import SwiftUI
import SwiftData

/// One timeline per grave: the funeral, the visits, the flowers, the stories —
/// in the order they happened, beginning on the day of the death.
///
/// It replaces three separate lists, because they were always one thing: what
/// has happened at this grave. Nothing is totalled or ranked. A timeline says
/// "this happened"; a total would say "somebody is winning" (PRD §9).
struct WallView: View {
    let grave: Grave

    @Environment(GraveStore.self) private var store
    @Environment(Presence.self) private var presence
    @Environment(Identity.self) private var identity
    @Environment(Lang.self) private var lang
    @Environment(WallStore.self) private var wallStore
    @Environment(\.modelContext) private var context

    @State private var composing = false

    private var isSteward: Bool {
        Records.isSteward(identity, graveID: grave.id, store: store, context: context)
    }

    private var visibility: WallVisibility {
        Records.wallVisibility(for: grave, context: context)
    }

    /// The steward sees everything, including what they have taken down.
    ///
    /// Local entries and CloudKit entries are the same posts seen twice — this
    /// phone keeps its own copy of whatever it wrote — so they are merged by id,
    /// with the local one winning because it is the one that can still be
    /// waiting to send.
    private var entries: [WallEntry] {
        let local = Records.wall(for: grave, store: store, context: context, includeRemoved: isSteward)
        let remote = wallStore.entries(for: grave.id, includeRemoved: isSteward)
        var byID: [String: WallEntry] = [:]
        for entry in remote { byID[entry.id] = entry }
        for entry in local { byID[entry.id] = entry }

        var entries = Array(byID.values)
        if let died = grave.deathDateValue {
            entries = entries.filter { $0.postedAt >= died }
        }
        return entries.sorted { $0.postedAt < $1.postedAt }
    }

    /// Reading is open to anyone the family allows; writing never depends on
    /// where you are, and a check-in always does.
    private var canRead: Bool {
        switch visibility {
        case .open: return true
        case .family: return isSteward
        case .closed: return isSteward
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if isSteward { visibilityControl }

                if canRead {
                    timeline
                } else {
                    Plaque {
                        Text(lang.t(.wallHiddenFromYou))
                            .font(.spoken(15))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(4)
                    }
                }

                actions
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 90)
        }
        .ground()
        .navigationTitle(lang.t(.wallTitle))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await wallStore.refresh(pushing: context) }
        .task { await wallStore.refresh(pushing: context) }
        .sheet(isPresented: $composing) {
            PostComposer(grave: grave)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(grave.name)
                .font(.engraved(26))
                .foregroundStyle(Palette.ink)
            if let died = grave.deathDateValue {
                Text(lang.t(.wallSince, lang.day(died)))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    @ViewBuilder
    private var timeline: some View {
        if entries.isEmpty {
            Plaque {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.t(.wallEmpty))
                        .font(.spoken(16))
                        .foregroundStyle(Palette.ink)
                    Text(lang.t(.wallEmptyNote))
                        .font(.spoken(14))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(3)
                }
            }
        } else {
            ForEach(entries) { entry in
                WallEntryCard(entry: entry, canModerate: isSteward) { decision in
                    Task {
                        await wallStore.decide(
                            decision,
                            postID: entry.id,
                            graveID: grave.id,
                            steward: identity.name,
                            context: context
                        )
                    }
                }
            }
        }
    }

    /// One way in, from anywhere. What the post *becomes* depends on where the
    /// phone is when it is written, not on which button was pressed.
    private var actions: some View {
        VStack(spacing: 10) {
            Button { composing = true } label: {
                Text(lang.t(presence.atGrave(grave) ? .wallCheckIn : .wallAddStory))
            }
            .buttonStyle(PrimaryButtonStyle())

            Text(lang.t(presence.atGrave(grave) ? .wallPostHereNote : .wallPostAwayNote))
                .font(.spoken(13))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.top, 4)
    }

    private var visibilityControl: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(lang.t(.wallVisibilityEyebrow))
                Picker(lang.t(.wallVisibilityEyebrow), selection: Binding(
                    get: { visibility },
                    set: { Records.setWallVisibility($0, for: grave.id, context: context) }
                )) {
                    ForEach(WallVisibility.allCases) { option in
                        Text(lang.t(option.labelKey)).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text(lang.t(visibility.noteKey))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)

                Text(lang.t(.wallModerationNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)
            }
        }
    }
}

struct WallEntryCard: View {
    let entry: WallEntry
    let canModerate: Bool
    var onDecision: (Memory.Approval) -> Void

    @Environment(Lang.self) private var lang

    private var whatHappened: String {
        guard entry.visitedInPerson else { return lang.t(.wallWroteStory) }
        return lang.t(entry.leftFlowers ? .wallVisitedWithFlowers : .wallVisited)
    }

    var body: some View {
        Plaque(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: entry.visitedInPerson
                          ? (entry.leftFlowers ? "leaf" : "figure.walk")
                          : "text.quote")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.grass)
                    Text(lang.day(entry.postedAt))
                        .font(.spoken(13))
                        .foregroundStyle(Palette.inkSoft)
                    Spacer(minLength: 8)
                }

                if let body = entry.body {
                    // A voice, so the serif — the same face as a name on a stone.
                    Text(body)
                        .font(.engraved(19))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.authorName) · \(whatHappened)")
                        .font(.spoken(14, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    if !entry.relationship.isEmpty {
                        Text(entry.relationship)
                            .font(.spoken(13))
                            .foregroundStyle(Palette.inkSoft)
                    }
                }

                if entry.approval == .pending {
                    LockNote(text: lang.t(canModerate ? .pendingSteward : .pendingFamily))
                }

                if canModerate {
                    HStack(spacing: 16) {
                        if entry.approval != .approved {
                            Button(lang.t(.moderateShow)) { onDecision(.approved) }
                                .font(.spoken(14))
                                .foregroundStyle(Palette.grassDeep)
                        }
                        if entry.approval != .removed {
                            Button(lang.t(.moderateRemove)) { onDecision(.removed) }
                                .font(.spoken(14))
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }
                }
            }
        }
    }
}
