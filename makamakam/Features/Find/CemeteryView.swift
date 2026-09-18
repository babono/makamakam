import SwiftUI

/// One burial ground. Finding a name happens here, inside a cemetery someone has
/// actually walked — not against a single national list of the dead, which is
/// neither what this survey is nor what it could honestly pretend to be.
struct CemeteryView: View {
    let site: Site

    @Environment(GraveStore.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(Presence.self) private var presence
    @Environment(Lang.self) private var lang

    @State private var term = ""
    @State private var heroIndex = 0
    @State private var openedPhoto: GravePhoto?
    @State private var tapped: Grave?
    @State private var showFullPlan = false
    @FocusState private var searchFocused: Bool

    private var photos: [GravePhoto] { store.photos(for: site) }

    private var cemeteryGraves: [Grave] { store.graves(in: site) }

    private var graves: [Grave] {
        let all = cemeteryGraves.sorted { $0.name < $1.name }
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        // Search inside this cemetery, not across every one the app knows.
        let ids = Set(cemeteryGraves.map(\.id))
        return store.search(term).filter { ids.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                hero
                header
                searchField

                plan

                Eyebrow(lang.t(.cemeteryGravesEyebrow))
                    .padding(.top, 4)

                if graves.isEmpty {
                    Plaque {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.t(.cemeteryNoGraves))
                                .font(.spoken(16))
                                .foregroundStyle(Palette.ink)
                            Text(lang.t(.cemeterySurveyNote))
                                .font(.spoken(14))
                                .foregroundStyle(Palette.inkSoft)
                                .lineSpacing(3)
                        }
                    }
                } else {
                    ForEach(graves) { grave in
                        NavigationLink(value: grave) { GraveRow(grave: grave) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // Clear of the floating tab bar, which otherwise sits over the last
            // row of graves.
            .padding(.bottom, 90)
        }
        .scrollDismissesKeyboard(.interactively)
        .ground()
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The photograph the pin carried, arriving as the first thing on the
    /// screen. Several of them page across; one fills the frame on its own.
    @ViewBuilder
    private var hero: some View {
        if photos.isEmpty {
            Plaque(padding: 14) {
                Text(lang.t(.cemeteryNoPhoto))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(3)
            }
        } else {
            VStack(spacing: 8) {
                TabView(selection: $heroIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        Button { openedPhoto = photo } label: {
                            GravePhotoImage(photo: photo)
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                        }
                        .buttonStyle(.plain)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.hairline, lineWidth: 1))

                if photos.count > 1 {
                    Text(lang.t(.cemeteryPhotoCount, heroIndex + 1, photos.count))
                        .font(.spoken(12))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .fullScreenCover(item: $openedPhoto) { photo in
                PhotoViewer(photo: photo) { openedPhoto = nil }
            }
        }
    }

    /// The spread, as it actually lies. Tapping a grave opens it — the plan is
    /// a way into the records, not only a picture of them.
    private var plan: some View {
        Plaque(padding: 12) {
            VStack(spacing: 8) {
                SitePlan(
                    site: site,
                    graves: cemeteryGraves,
                    target: nil,
                    here: location.location,
                    // North stays up here, as on the full-screen plan. Turning
                    // with the phone belongs to the walk, where you are matching
                    // the drawing to what is in front of you; while reading a
                    // list of names it only makes the page swing.
                    heading: nil,
                    onSelect: { tapped = $0 }
                )
                .frame(height: 260)

                HStack(alignment: .top, spacing: 10) {
                    Text(unplaced > 0 ? lang.t(.planSomeUnplaced, unplaced) : lang.t(planCaption))
                        .font(.spoken(12))
                        .foregroundStyle(Palette.inkSoft)
                    Spacer(minLength: 8)
                    Button { showFullPlan = true } label: {
                        Label(lang.t(.planExpand), systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.spoken(12, weight: .medium))
                            .foregroundStyle(Palette.grassDeep)
                    }
                }
            }
        }
        .navigationDestination(item: $tapped) { GraveView(grave: $0) }
        .fullScreenCover(isPresented: $showFullPlan) {
            PlanScreen(site: site, graves: cemeteryGraves)
        }
        .task {
            if Demo.screen == .plan { showFullPlan = true }
        }
    }

    /// Graves recorded from a stone that nobody has measured yet.
    private var unplaced: Int {
        cemeteryGraves.filter { !$0.isPositioned }.count
    }

    /// How far there is to go, which is the whole invitation.
    private var distanceLine: String {
        if presence.isAt(site) { return lang.t(.lockAtSite) }
        guard let metres = presence.metres(from: site) else { return lang.t(.lockDistanceUnknown) }
        return lang.t(.lockDistance, Distance.journeyText(metres))
    }

    /// Says only what the drawing actually shows — and never contradicts the
    /// line above it.
    ///
    /// The header speaks for `Presence`, which the field sheet can override; the
    /// plan can only draw a position the phone actually has. When those two
    /// disagree — the override is on, or there is no fix at all — the caption
    /// says which, rather than flatly denying what the header just claimed.
    private var planCaption: S {
        guard let here = location.location else { return .planNoFix }
        if presence.pretendPresent { return .planPretending }
        let position = Geo.localOffset(of: here.coordinate, from: site.coordinate)
        let far = abs(position.x) > 200 || abs(position.y) > 200
        return far ? .planYouElsewhere : .planYouAre
    }

    private var header: some View {
        Plaque {
            VStack(alignment: .leading, spacing: 8) {
                Text(site.name)
                    .font(.spoken(22, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(site.address)
                    .font(.spoken(14))
                    .foregroundStyle(Palette.inkSoft)
                Text(lang.t(.nearbySurveyed))
                    .font(.spoken(11, weight: .medium))
                    .foregroundStyle(Palette.grassDeep)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Palette.grassPale.opacity(0.5)))
                Text(lang.t(.cemeterySurveyNote))
                    .font(.spoken(12))
                    .foregroundStyle(Palette.inkSoft)
                    .lineSpacing(2)
                    .padding(.top, 2)

                Text(distanceLine)
                    .font(.spoken(14, weight: .medium))
                    .foregroundStyle(presence.isAt(site) ? Palette.grassDeep : Palette.ink)
                    .padding(.top, 4)
            }
        }
    }

    private var searchField: some View {
        Plaque(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Palette.inkSoft)
                    TextField(lang.t(.cemeteryGraveSearch), text: $term)
                        .font(.spoken(17))
                        .foregroundStyle(Palette.ink)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.search)
                    if !term.isEmpty {
                        Button {
                            term = ""
                            searchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Palette.hairline)
                        }
                        .accessibilityLabel(lang.t(.searchClearAccessibility))
                    }
                }
                if term.isEmpty {
                    Text(lang.t(.findPrivacyNote))
                        .font(.spoken(12))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(2)
                }
            }
        }
    }
}
