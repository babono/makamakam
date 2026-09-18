import SwiftUI
import CloudKit

struct SettingsView: View {
    /// Set by the demo launch argument; otherwise this opens only on a long
    /// press of the version number.
    var openFieldSheet: Binding<Bool>? = nil

    @Environment(Identity.self) private var identity
    @Environment(GraveStore.self) private var store
    @Environment(Lang.self) private var lang
    @Environment(ApproachPulse.self) private var pulse
    @Environment(WallStore.self) private var wallStore
    @State private var showDeveloper = false

    private var developerSheet: Binding<Bool> {
        openFieldSheet ?? $showDeveloper
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return lang.t(.versionLine, v, b)
    }

    var body: some View {
        NavigationStack {
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(lang.t(.aboutLede))
                        .font(.spoken(15))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(5)
                }
                .padding(.top, 4)

                languagePlaque
                icloudPlaque
                syncPlaque
                hapticsPlaque
                youPlaque
                principlesPlaque
                dataPlaque

                Text(version)
                    .font(.spoken(12))
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .center)
                    // Field capture lives behind a long press on the version
                    // number (PRD §14) so it never appears to a visitor.
                    .onLongPressGesture(minimumDuration: 1.2) { developerSheet.wrappedValue = true }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .ground()
        .navigationTitle(lang.t(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: developerSheet) {
            NavigationStack { DeveloperView() }
        }
    }

    private var languagePlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(lang.t(.languageEyebrow))
                Picker(lang.t(.languageEyebrow), selection: Binding(
                    get: { lang.code },
                    set: { lang.code = $0 }
                )) {
                    ForEach(LanguageCode.allCases) { code in
                        Text(code.label).tag(code)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    /// What iCloud is doing here, in words rather than in a settings screen
    /// somebody has to go looking for.
    private var icloudPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(lang.t(.icloudEyebrow))

                Text(lang.t(accountLine))
                    .font(.spoken(15))
                    .foregroundStyle(wallStore.canWrite ? Palette.ink : Palette.engraved)
                    .lineSpacing(3)

                Text(lang.t(.icloudNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)

                Text(lang.t(.icloudQuotaNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)
            }
        }
    }

    private var accountLine: S {
        switch wallStore.account {
        case .available: return .icloudSignedIn
        case .noAccount: return .icloudNoAccount
        case .restricted: return .icloudRestricted
        default: return .icloudUnknown
        }
    }

    private var syncPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(lang.t(.syncEyebrow))

                Text(syncLine)
                    .font(.spoken(14))
                    .foregroundStyle(Palette.ink)

                if store.lastSyncFailed {
                    Text(lang.t(.syncFailed))
                        .font(.spoken(13))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(3)
                }

                Text(lang.t(.syncNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)

                Button {
                    Task { await store.refresh() }
                } label: {
                    Text(lang.t(.syncRefresh))
                }
                .buttonStyle(PrimaryButtonStyle(filled: false))
                .disabled(store.isSyncing || !store.canSync)
            }
        }
    }

    private var syncLine: String {
        if !store.canSync { return lang.t(.syncUnavailable) }
        if store.isSyncing { return lang.t(.syncChecking) }
        guard let date = store.lastSynced else { return lang.t(.syncNever) }
        return lang.t(.syncAt, lang.day(date))
    }

    private var hapticsPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(lang.t(.hapticsEyebrow))
                Toggle(isOn: Binding(get: { pulse.enabled }, set: { pulse.enabled = $0 })) {
                    Text(lang.t(.hapticsToggle))
                        .font(.spoken(16))
                        .foregroundStyle(Palette.ink)
                }
                .tint(Palette.grass)
                Text(lang.t(.hapticsNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)
            }
        }
    }

    private var youPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(lang.t(.aboutYouEyebrow))
                Text(lang.t(.aboutYouNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)

                TextField(lang.t(.fieldName), text: Binding(get: { identity.name }, set: { identity.name = $0 }))
                    .font(.spoken(17))
                    .textInputAutocapitalization(.words)
                Hairline()

                TextField(lang.t(.fieldRelationship), text: Binding(get: { identity.relationship }, set: { identity.relationship = $0 }))
                    .font(.spoken(17))
                Hairline()

                Toggle(isOn: Binding(get: { identity.isImmediateFamily }, set: { identity.isImmediateFamily = $0 })) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lang.t(.familyToggle))
                            .font(.spoken(16))
                            .foregroundStyle(Palette.ink)
                        Text(lang.t(.familyToggleNote))
                            .font(.spoken(13))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(3)
                    }
                }
                .tint(Palette.grass)

                Picker(lang.t(.guidanceLabel), selection: Binding(get: { identity.tradition }, set: { identity.tradition = $0 })) {
                    ForEach(Tradition.allCases) { Text($0.label(lang)).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .padding(.top, 2)
            }
        }
    }

    private var principlesPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(lang.t(.notDoingEyebrow))
                principle(lang.t(.principleNotifications))
                principle(lang.t(.principleCounts))
                principle(lang.t(.principleNothingAdded))
                principle(lang.t(.principlePurchases))
                principle(lang.t(.principleNoVirtual))
            }
        }
    }

    private var dataPlaque: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(lang.t(.dataEyebrow))
                Text(lang.t(.dataNote, store.site.name))
                    .font(.spoken(14))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(4)
                Text(lang.t(.prayerReviewNote))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)
            }
        }
    }

    private func principle(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Palette.grass)
                .frame(width: 10, height: 1)
                .padding(.top, 10)
            Text(text)
                .font(.spoken(14))
                .foregroundStyle(Palette.inkSoft)
                .lineSpacing(4)
        }
    }
}
