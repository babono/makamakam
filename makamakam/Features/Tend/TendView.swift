import SwiftUI
import SwiftData

/// Screen 5. What to do while standing there.
///
/// All three parts are acts, so all three need a body in this place (PRD §3).
struct TendView: View {
    let grave: Grave

    @Environment(GraveStore.self) private var store
    @Environment(Identity.self) private var identity
    @Environment(Lang.self) private var lang
    @Environment(\.modelContext) private var context

    /// Set only when the reader deliberately picks a different set of texts for
    /// this visit. It is never written back to their settings.
    @State private var overrideTradition: Tradition?

    /// The rite belongs to the person buried here. Their recorded faith decides
    /// the guidance; the reader's own setting is only the fallback for a grave
    /// whose faith the survey could not confirm.
    private var tradition: Tradition {
        if let overrideTradition { return overrideTradition }
        if grave.faith.isRecorded { return grave.faith.tradition }
        return Tradition(rawValue: identity.tradition) ?? .islam
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                PretendPresenceBadge()

                // No presence check. A doa recited alone in a room is valid —
                // that is the rule's own reasoning — so the words are readable
                // from anywhere. Only the check-in asserts presence (PRD §3).
                prayerSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .ground()
        .navigationTitle(lang.t(.tendTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(grave.name)
                .font(.engraved(26))
                .foregroundStyle(Palette.ink)

        }
        .padding(.top, 4)
    }

    // MARK: Prayer

    private var prayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(lang.t(.tendGuidanceEyebrow))
                Spacer()
                Menu {
                    ForEach(Tradition.allCases) { option in
                        Button(option.label(lang)) { overrideTradition = option }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(tradition.label(lang)).font(.spoken(13))
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .foregroundStyle(Palette.grassDeep)
                }
            }

            Text(provenance)
                .font(.spoken(13))
                .foregroundStyle(Palette.inkSoft)
                .lineSpacing(3)

            if let note = guidanceUnavailableNote {
                Plaque {
                    Text(note)
                        .font(.spoken(14))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(4)
                }
            }

            ForEach(PrayerLibrary.groups(for: tradition)) { group in
                Plaque {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.title(lang))
                            .font(.spoken(17, weight: .medium))
                            .foregroundStyle(Palette.ink)
                        Text(group.subtitle(lang))
                            .font(.spoken(13))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(3)
                        VStack(spacing: 0) {
                            ForEach(group.passages) { passage in
                                NavigationLink {
                                    PassageView(passage: passage)
                                } label: {
                                    HStack {
                                        Text(passage.title)
                                            .font(.spoken(16))
                                            .foregroundStyle(Palette.ink)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Palette.hairline)
                                    }
                                    .padding(.vertical, 13)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                if passage.id != group.passages.last?.id { Hairline() }
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    /// Says where these particular words came from, so nobody has to guess
    /// whether the app knows or is assuming.
    private var provenance: String {
        if grave.faith.isRecorded {
            return lang.t(.guidanceFollowsRecord, lang.t(grave.faith.labelKey))
        }
        return lang.t(.guidanceFallback)
    }

    /// A faith with no bundled text says so by name, rather than silently
    /// offering somebody else's prayers.
    private var guidanceUnavailableNote: String? {
        if grave.faith.isRecorded, grave.faith.tradition == .umum, overrideTradition == nil {
            return lang.t(.guidanceNoneForFaith, lang.t(grave.faith.labelKey))
        }
        return PrayerLibrary.unavailableNote(for: tradition, lang: lang)
    }

}

/// One passage, set large enough to read outdoors at arm's length.
struct PassageView: View {
    let passage: Passage
    @Environment(Lang.self) private var lang

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(passage.title)
                        .font(.spoken(24, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    if let note = passage.note(lang) {
                        Text(note)
                            .font(.spoken(14))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(3)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)

                Plaque(padding: 22) {
                    Text(passage.arabic)
                        .font(.arabic(30))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(18)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                Plaque {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(lang.t(.passageHowToRead))
                        Text(passage.latin)
                            .font(.spoken(18))
                            .foregroundStyle(Palette.ink)
                            .lineSpacing(7)
                    }
                }

                Plaque {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(lang.t(.passageMeaning))
                        Text(passage.meaning(lang))
                            .font(.spoken(17))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(7)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 56)
        }
        .ground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
