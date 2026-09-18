import SwiftUI
import SwiftData

/// Everything one person can do about one grave. Each door says plainly whether
/// it needs you to be standing there.
struct GraveView: View {
    let grave: Grave

    @Environment(GraveStore.self) private var store
    @Environment(Presence.self) private var presence
    @Environment(Identity.self) private var identity
    @Environment(Lang.self) private var lang
    @Environment(SavedSync.self) private var savedSync
    @Environment(\.modelContext) private var context

    @State private var showGuide = false

    private var stewardName: String? {
        Records.steward(for: grave.id, store: store, context: context)
    }

    /// Observed, not fetched.
    ///
    /// This was a plain fetch, which SwiftData has no reason to re-run when the
    /// store changes — so the bookmark kept its old shape after a tap. It looked
    /// as though nothing had happened, which invites a second tap, which
    /// un-keeps the grave. The list really was empty; the button was lying about
    /// why.
    @Query private var keptGraves: [SavedGrave]

    private var isSaved: Bool { keptGraves.contains { $0.graveID == grave.id } }

    /// "Done at the cemetery · 12 km away" — the lock and the reason to travel,
    /// in one line.
    private func lockNote(_ key: S) -> String {
        let base = lang.t(key)
        guard let metres = presence.metresFromSite else { return base }
        return "\(base) · \(Distance.journeyText(metres))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                nameplate
                GravePhotoStrip(photos: grave.photoList)
                doors
                if let stewardName {
                    stewardPlaque(stewardName)
                } else if identity.isImmediateFamily {
                    claimPlaque
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .ground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let kept = Records.toggleSaved(grave.id, context: context)
                    Task {
                        if kept {
                            await savedSync.sync(context: context)
                        } else {
                            await savedSync.forget(graveID: grave.id)
                        }
                    }
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(Palette.ink)
                }
                .accessibilityLabel(lang.t(isSaved ? .graveUnsave : .graveSave))
            }
        }
        .fullScreenCover(isPresented: $showGuide) {
            GuideFlowView(grave: grave)
        }
    }

    /// The name, on marble, the way it is on the stone.
    private var nameplate: some View {
        Plaque(padding: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(grave.name)
                    .font(.engraved(34))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let parentage = grave.parentageLine(lang) {
                    Text(parentage)
                        .font(.engraved(19))
                        .foregroundStyle(Palette.inkSoft)
                }
                Text(grave.yearsLine(lang))
                    .font(.spoken(15))
                    .foregroundStyle(Palette.inkSoft)
                if let day = grave.deathDateLine(lang) {
                    Text(lang.t(.diedOn, day))
                        .font(.spoken(15))
                        .foregroundStyle(Palette.inkSoft)
                }
                HStack(spacing: 10) {
                    // The caretaker's number, where a caretaker keeps one. It
                    // says nothing about where the grave is — that is the plan's
                    // job — so it sits here and nowhere else.
                    if let plotLabel = grave.plotLabel(lang) {
                        Text(plotLabel)
                            .font(.spoken(13, weight: .medium))
                            .foregroundStyle(Palette.inkSoft)
                    }
                    VerificationMark(verified: grave.verified)
                }
                .padding(.top, 4)

                Text(lang.t(grave.faith.labelKey))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .padding(.top, 4)
    }

    private var doors: some View {
        VStack(spacing: 10) {
            Button { showGuide = true } label: {
                Door(title: lang.t(.doorGuideTitle),
                     detail: lang.t(.doorGuideDetail),
                     lockNote: nil)
            }
            .buttonStyle(.plain)

            NavigationLink { TendView(grave: grave) } label: {
                Door(title: lang.t(.doorTendTitle),
                     detail: lang.t(.doorTendDetail),
                     lockNote: nil)
            }
            .buttonStyle(.plain)

            NavigationLink { WallView(grave: grave) } label: {
                // The only lock left in the product: a post made here is
                // recorded as a visit, and that has to be earned.
                Door(title: lang.t(.doorWallTitle),
                     detail: lang.t(.doorWallDetail),
                     lockNote: presence.atGrave(grave) ? lang.t(.wallCanCheckIn) : nil)
            }
            .buttonStyle(.plain)

            NavigationLink { ProfileView(grave: grave) } label: {
                Door(title: lang.t(.doorProfileTitle),
                     detail: lang.t(.doorProfileDetail),
                     lockNote: nil)
            }
            .buttonStyle(.plain)

        }
    }

    private func stewardPlaque(_ name: String) -> some View {
        Plaque {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(lang.t(.stewardEyebrow))
                Text(name)
                    .font(.spoken(15))
                    .foregroundStyle(Palette.ink)
                Text(lang.t(.stewardNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)
            }
        }
    }

    private var claimPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 12) {
                Text(lang.t(.claimNone))
                    .font(.spoken(14))
                    .foregroundStyle(Palette.inkSoft)
                Button {
                    guard identity.isNamed else { return }
                    Records.claimStewardship(graveID: grave.id, name: identity.name, context: context)
                } label: {
                    Text(lang.t(identity.isNamed ? .claimButton : .claimNeedsName))
                }
                .buttonStyle(PrimaryButtonStyle(filled: false))
                .disabled(!identity.isNamed)
            }
        }
    }
}

private struct Door: View {
    let title: String
    let detail: String
    let lockNote: String?

    var body: some View {
        Plaque(padding: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.spoken(19, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Text(detail)
                        .font(.spoken(14))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                    if let lockNote {
                        LockNote(text: lockNote).padding(.top, 2)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.hairline)
                    .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
    }
}
