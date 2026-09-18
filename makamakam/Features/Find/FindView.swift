import SwiftUI
import SwiftData
import MapKit

/// Screen 1. The cemetery, full screen, with a search field over it and a panel
/// beneath holding the graves you keep and the other burial grounds nearby.
///
/// The map stays at cemetery scale. It marks burial grounds — never individual
/// graves: 27 pins at this zoom would be 44 pt targets on 1 m plots, precise
/// looking and false (PRD §7). Everything closer than the gate is the section
/// plan's job.
struct FindView: View {
    @Binding var path: NavigationPath

    @Environment(GraveStore.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang
    @State private var term = ""
    @State private var camera: MapCameraPosition = .automatic
    @State private var nearby = NearbyCemeteries()
    @State private var selectedMarker: String?
    /// Cemeteries found by typing, anywhere in the country. Kept apart from the
    /// ambient 25 km set so a search never quietly redraws what is around you.
    @State private var elsewhere: [NearbyPlace] = []
    @State private var searchingElsewhere = false
    /// Carries the surveyed cemetery's photograph from its pin into the screen
    /// it opens, so the two are visibly the same object (see BUILD-NOTES).
    @Namespace private var heroNamespace
    @FocusState private var searchFocused: Bool

    /// The search at the top of the map looks for burial grounds. Names of the
    /// dead are searched inside one, on the cemetery's own screen.
    private var matchingSurveyed: [Site] {
        let query = term.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        return store.cemeteries.filter {
            $0.name.lowercased().contains(query) || $0.address.lowercased().contains(query)
        }
    }

    private var matchingNearby: [NearbyPlace] {
        let query = term.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        return nearbyPlaces.filter {
            $0.name.lowercased().contains(query) || $0.locality.lowercased().contains(query)
        }
    }

    /// Anything the typed search found that is not already on the nearby list.
    private var matchingElsewhere: [NearbyPlace] {
        let known = Set(matchingNearby.map(\.id))
        return elsewhere.filter { !known.contains($0.id) }
    }

    private var hasResults: Bool {
        !matchingSurveyed.isEmpty || !matchingNearby.isEmpty || !matchingElsewhere.isEmpty
    }

    private var nearbyPlaces: [NearbyPlace] {
        if case let .ready(places) = nearby.state { return places }
        return []
    }

    /// A cemetery found by typing stays on the map while its card is open, even
    /// once the search field has been cleared.
    private var selectedElsewhere: [NearbyPlace] {
        guard let selectedMarker,
              let place = elsewhere.first(where: { $0.id == selectedMarker }),
              !nearbyPlaces.contains(place) else { return [] }
        return [place]
    }

    /// Wide enough that the neighbouring burial grounds are on screen from the
    /// start — roughly 7 km across, against a 25 km search radius.
    private var region: MKCoordinateRegion {
        let coordinates = store.cemeteries.map(\.coordinate)
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: store.site.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        }
        // Wide enough to hold every surveyed cemetery, and never tighter than
        // the district around one.
        let lats = coordinates.map(\.latitude), lons = coordinates.map(\.longitude)
        let centre = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        _ = first
        return MKCoordinateRegion(
            center: centre,
            span: MKCoordinateSpan(
                latitudeDelta: max((lats.max()! - lats.min()!) * 1.6, 0.06),
                longitudeDelta: max((lons.max()! - lons.min()!) * 1.6, 0.06)
            )
        )
    }

    private var locationAuthorized: Bool {
        location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                map
                overlay
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Site.self) { site in
                cemeteryDestination(site)
            }
            .navigationDestination(for: Grave.self) { GraveView(grave: $0) }
            .navigationDestination(for: Demo.Screen.self) { screen in
                if let grave = store.grave(id: Demo.graveID) {
                    switch screen {
                    case .tend: TendView(grave: grave)
                    case .wall: WallView(grave: grave)
                    case .profile: ProfileView(grave: grave)
                    case .orient: GuideFlowView(grave: grave, initialStage: .orient)
                    case .approach: GuideFlowView(grave: grave, initialStage: .approach)
                    case .arrive: GuideFlowView(grave: grave, initialStage: .arrive)
                    default: GraveView(grave: grave)
                    }
                }
            }
        }
        .onAppear {
            camera = .region(region)
            if let prefilled = Demo.search { term = prefilled }
        }
        .task(id: term) {
            let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard query.count >= 3 else {
                elsewhere = []
                searchingElsewhere = false
                return
            }
            // Let the typing settle before asking Apple anything.
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            searchingElsewhere = true
            let origin = location.location?.coordinate ?? store.site.coordinate
            let found = await NearbyCemeteries.searchAnywhere(term: query, from: origin)
            guard !Task.isCancelled else { return }
            elsewhere = found
            searchingElsewhere = false
        }
        .task(id: location.location?.coordinate.latitude) {
            // The user's own position if it is known, the surveyed cemetery
            // otherwise, so the list is useful before any permission is granted.
            let centre = location.location?.coordinate ?? store.site.coordinate
            await nearby.search(near: centre, excluding: store.cemeteries)
            if Demo.selectsFirstNearbyPin, let first = nearbyPlaces.first {
                selectedMarker = first.id
            }
        }
    }

    private var map: some View {
        Map(position: $camera, selection: $selectedMarker) {
            // The surveyed cemetery wears its own photograph. Tapping it opens
            // the cemetery, and on iOS 18 the picture flies into place as the
            // screen's hero rather than being replaced by a different one.
            ForEach(store.cemeteries) { cemetery in
                Annotation(cemetery.name, coordinate: cemetery.coordinate) {
                    Button {
                        selectedMarker = nil
                        path.append(cemetery)
                    } label: {
                        sitePin(for: cemetery)
                    }
                    .buttonStyle(.plain)
                }
                .tag(cemetery.id)
            }

            // Other burial grounds sit far enough apart to mark honestly, so
            // they are pins you can tap rather than another list to read.
            ForEach(nearbyPlaces) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    CemeteryPin(photo: nil, surveyed: false, selected: selectedMarker == place.id)
                }
                .tag(place.id)
            }

            ForEach(matchingElsewhere.isEmpty ? selectedElsewhere : matchingElsewhere) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    CemeteryPin(photo: nil, surveyed: false, selected: selectedMarker == place.id)
                }
                .tag(place.id)
            }

            if locationAuthorized { UserAnnotation() }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func sitePin(for cemetery: Site) -> some View {
        let pin = CemeteryPin(photo: store.photos(for: cemetery).first,
                              surveyed: true,
                              selected: selectedMarker == cemetery.id)
        if #available(iOS 18, *) {
            pin.matchedTransitionSource(id: cemetery.id, in: heroNamespace)
        } else {
            pin
        }
    }

    private var selectedPlace: NearbyPlace? {
        guard let selectedMarker, selectedCemetery == nil else { return nil }
        return (nearbyPlaces + elsewhere).first { $0.id == selectedMarker }
    }

    private var selectedCemetery: Site? {
        guard let selectedMarker else { return nil }
        return store.cemetery(id: selectedMarker)
    }

    private var overlay: some View {
        VStack(spacing: 10) {
            searchField

            if !term.isEmpty {
                resultsList
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                mapControls
                // Nothing rests over the map. A cemetery speaks when its pin is
                // tapped, the way a map is expected to behave, and the graves
                // someone keeps live in their own tab.
                if let selected = selectedMarker {
                    selectionCard(for: selected)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .quiet(selectedMarker)
    }

    private var searchField: some View {
        Plaque(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Palette.inkSoft)
                    TextField(lang.t(.findCemeteryPlaceholder), text: $term)
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
                    Text(lang.t(.findCemeteryPrivacyNote))
                        .font(.spoken(12))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(2)
                }
            }
        }
    }

    private var resultsList: some View {
        Plaque(padding: 0) {
            // Capped and scrollable: a city search can come back with twenty
            // burial grounds, and the list must never grow over the field that
            // produced it.
            ScrollView {
                VStack(spacing: 0) {
                if !hasResults {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lang.t(.findNoCemeteries))
                            .font(.spoken(16))
                            .foregroundStyle(Palette.ink)
                        Text(lang.t(.findNoCemeteriesNote))
                            .font(.spoken(14))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                } else {
                    ForEach(matchingSurveyed) { cemetery in
                        NavigationLink(value: cemetery) {
                            CemeteryRow(name: cemetery.name,
                                        detail: cemetery.address,
                                        surveyed: true)
                        }
                        .buttonStyle(.plain)
                        Hairline()
                    }
                    if !matchingNearby.isEmpty {
                        resultsHeader(lang.t(.resultsNearby))
                    }
                    ForEach(matchingNearby) { place in
                        Button { show(place) } label: {
                            CemeteryRow(name: place.name,
                                        detail: place.locality.isEmpty
                                            ? place.distanceText
                                            : "\(place.distanceText) · \(place.locality)",
                                        surveyed: false)
                        }
                        .buttonStyle(.plain)
                        if place.id != matchingNearby.last?.id { Hairline() }
                    }

                    if !matchingElsewhere.isEmpty {
                        Hairline()
                        resultsHeader(lang.t(.resultsElsewhere))
                        ForEach(matchingElsewhere.isEmpty ? selectedElsewhere : matchingElsewhere) { place in
                            Button { show(place) } label: {
                                CemeteryRow(name: place.name,
                                            detail: place.locality.isEmpty
                                                ? place.distanceText
                                                : "\(place.distanceText) · \(place.locality)",
                                            surveyed: false)
                            }
                            .buttonStyle(.plain)
                            if place.id != matchingElsewhere.last?.id { Hairline() }
                        }
                    }
                }

                if searchingElsewhere {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text(lang.t(.resultsSearching))
                            .font(.spoken(13))
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(maxHeight: 430)
            .scrollBounceBehavior(.basedOnSize)
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private func cemeteryDestination(_ site: Site) -> some View {
        let screen = CemeteryView(site: site)
        if #available(iOS 18, *) {
            screen.navigationTransition(.zoom(sourceID: site.id, in: heroNamespace))
        } else {
            screen
        }
    }

    private func resultsHeader(_ text: String) -> some View {
        Eyebrow(text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    /// Moves the map to a cemetery and opens its pin, wherever in the country it
    /// turned out to be.
    private func show(_ place: NearbyPlace) {
        term = ""
        searchFocused = false
        selectedMarker = place.id
        withAnimation(.easeInOut(duration: 0.6)) {
            camera = .region(MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private var mapControls: some View {
        HStack(alignment: .bottom) {
            if !nearbyPlaces.isEmpty { legend }
            Spacer(minLength: 8)
            Button {
                selectedMarker = nil
                withAnimation(.easeInOut(duration: 0.5)) { camera = .region(region) }
            } label: {
                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.grassDeep)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Palette.plaque)
                            .shadow(color: .black.opacity(0.14), radius: 3, y: 2)
                    )
            }
            .accessibilityLabel(lang.t(.findRecentre))
        }
    }

    /// What the two kinds of pin mean, in the words that matter to someone
    /// looking for a person: how far this app can take them.
    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(symbol: "text.magnifyingglass",
                      tint: Palette.grass,
                      text: lang.t(.legendSurveyed))
            legendRow(symbol: "leaf",
                      tint: Palette.graniteDeep,
                      text: lang.t(.legendNotSurveyed))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Palette.plaque)
                .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
        )
    }

    private func legendRow(symbol: String, tint: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Palette.plaque)
                .frame(width: 18, height: 18)
                .background(Circle().fill(tint))
            Text(text)
                .font(.spoken(12))
                .foregroundStyle(Palette.ink)
        }
    }

    @ViewBuilder
    private func selectionCard(for marker: String) -> some View {
        if let cemetery = selectedCemetery {
            Plaque(padding: 0) { surveyedSiteCard(cemetery) }
                .transition(.opacity)
        } else if let place = selectedPlace {
            Plaque(padding: 0) {
                NearbyPlaceCard(place: place) { selectedMarker = nil }
            }
            .transition(.opacity)
        }
    }

    /// The one cemetery this app actually knows the inside of.
    private func surveyedSiteCard(_ cemetery: Site) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.grass)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(cemetery.name)
                        .font(.spoken(16, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                    Text(lang.t(.findMapCaveat))
                        .font(.spoken(12))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                    Text(lang.t(.nearbySurveyed))
                        .font(.spoken(11, weight: .medium))
                        .foregroundStyle(Palette.grassDeep)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Palette.grassPale.opacity(0.5)))
                }

                Spacer(minLength: 8)

                Button { selectedMarker = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                }
                .accessibilityLabel(lang.t(.nearbyDismiss))
            }

            NavigationLink(value: cemetery) {
                Label(lang.t(.cemeteryOpen), systemImage: "magnifyingglass")
                    .font(.spoken(17, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Palette.plaque)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Palette.grass))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

}

/// A cemetery the app has no survey for. It can take you to the gate, and it
/// says so rather than implying it could do more.
private struct NearbyPlaceCard: View {
    let place: NearbyPlace
    var onDismiss: () -> Void

    @Environment(Lang.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "leaf")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.graniteDeep)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.spoken(16, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                    Text(place.locality.isEmpty
                         ? place.distanceText
                         : "\(place.distanceText) · \(place.locality)")
                        .font(.spoken(13))
                        .foregroundStyle(Palette.inkSoft)
                    Text(lang.t(.nearbyNotSurveyed))
                        .font(.spoken(12))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                    // Where the pin came from, since it did not come from us.
                    Text(lang.t(.nearbyFromAppleMaps))
                        .font(.spoken(11))
                        .foregroundStyle(Palette.inkSoft.opacity(0.8))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                }
                .accessibilityLabel(lang.t(.nearbyDismiss))
            }

            Button { place.openInMaps() } label: {
                Label(lang.t(.nearbyDirections), systemImage: "arrow.triangle.turn.up.right.circle")
            }
            .buttonStyle(PrimaryButtonStyle(filled: false))
        }
        .padding(16)
    }
}

/// A row inside a plaque — no card of its own, since it already sits on one.
private struct ResultRow: View {
    let grave: Grave
    @Environment(Lang.self) private var lang

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(grave.name)
                    .font(.engraved(20))
                    .foregroundStyle(Palette.ink)
                Text(grave.plotLabel(lang).map { "\(grave.yearsLine(lang))  ·  \($0)" }
                     ?? grave.yearsLine(lang))
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.hairline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

/// A grave on a marble card, used wherever graves are listed away from the map.
struct GraveRow: View {
    let grave: Grave
    @Environment(Lang.self) private var lang

    var body: some View {
        Plaque(padding: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(grave.name)
                        .font(.engraved(21))
                        .foregroundStyle(Palette.ink)
                    // The ledger number rides along only where a cemetery keeps
                    // one — it is a reference, not a location.
                    Text(grave.plotLabel(lang).map { "\(grave.yearsLine(lang))  ·  \($0)" }
                         ?? grave.yearsLine(lang))
                        .font(.spoken(13))
                        .foregroundStyle(Palette.inkSoft)
                }
                Spacer(minLength: 12)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.hairline)
            }
        }
        .contentShape(Rectangle())
    }
}

/// A burial ground in a results list: the surveyed one in grass, the rest in
/// granite, each saying which it is.
struct CemeteryRow: View {
    let name: String
    let detail: String
    let surveyed: Bool

    @Environment(Lang.self) private var lang

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: surveyed ? "text.magnifyingglass" : "leaf")
                .font(.system(size: 15))
                .foregroundStyle(surveyed ? Palette.grass : Palette.graniteDeep)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.spoken(16, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(.spoken(13))
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.leading)
                Text(lang.t(surveyed ? .nearbySurveyed : .nearbyNotSurveyed))
                    .font(.spoken(11))
                    .foregroundStyle(surveyed ? Palette.grassDeep : Palette.inkSoft)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            Image(systemName: surveyed ? "chevron.right" : "mappin.and.ellipse")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.hairline)
                .padding(.top, 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
