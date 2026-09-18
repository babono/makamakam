import Foundation
import MapKit
import Observation

/// Other burial grounds within 25 km.
///
/// This is the one part of the app that needs the network, and it is the one
/// part that may quietly fail: Apple's point-of-interest search is a live query.
/// Nothing else depends on it — the surveyed cemetery, its graves, the prayers
/// and every private note keep working with the radio off (PRD §13), so when
/// this cannot run the section simply says so.
///
/// These cemeteries carry no survey. The app can point you at the gate and
/// nothing further, and it says exactly that rather than implying it could walk
/// you to a grave inside one.
@Observable
final class NearbyCemeteries {
    enum State: Equatable {
        case idle
        case searching
        case ready([NearbyPlace])
        case unavailable
    }

    private(set) var state: State = .idle
    private var lastSearchCentre: CLLocationCoordinate2D?

    static let radius: CLLocationDistance = 25_000

    /// What the sign on the gate might say, in Indonesian and in English.
    static let queries = ["pemakaman", "makam", "cemetery"]

    static let names = ["pemakaman", "makam", "kuburan", "setra", "tpu",
                                "cemetery", "graveyard", "memorial park"]

    /// Two names for one burial ground: "Pemakaman Islam II Lingkungan Desa Adat
    /// Kuta" and "Pemakaman Islam II, Lingkungan Desa Adat Kuta".
    private static func isSamePlace(_ name: String, as siteName: String) -> Bool {
        func words(_ text: String) -> Set<String> {
            Set(text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 })
        }
        let a = words(name)
        let b = words(siteName)
        guard !a.isEmpty, !b.isEmpty else { return false }
        let shared = Double(a.intersection(b).count)
        return shared / Double(min(a.count, b.count)) >= 0.7
    }

    static func namesABurialGround(_ name: String) -> Bool {
        let lowered = name.lowercased()
        return names.contains { lowered.contains($0) }
    }

    func search(near centre: CLLocationCoordinate2D, excluding surveyed: [Site]) async {
        // Don't re-query for every GPS nudge; a few hundred metres changes nothing.
        if let last = lastSearchCentre,
           CLLocation(latitude: last.latitude, longitude: last.longitude)
            .distance(from: CLLocation(latitude: centre.latitude, longitude: centre.longitude)) < 500,
           case .ready = state {
            return
        }
        lastSearchCentre = centre
        state = .searching

        // MapKit has no cemetery point-of-interest category, so this asks the
        // way a person would, in both languages the sign might be written in.
        let span = MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
        let region = MKCoordinateRegion(center: centre, span: span)
        let origin = CLLocation(latitude: centre.latitude, longitude: centre.longitude)
        let surveyedLocations = surveyed.map(\.location)

        var found: [String: NearbyPlace] = [:]
        var anySucceeded = false

        for term in Self.queries {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = region
            request.resultTypes = [.pointOfInterest, .address]

            guard let response = try? await MKLocalSearch(request: request).start() else { continue }
            anySucceeded = true

            for item in response.mapItems {
                guard let coordinate = item.placemark.location?.coordinate else { continue }
                let name = item.name ?? item.placemark.name ?? ""
                // A free-text search returns whatever is near the words, so the
                // name has to actually say burial ground before it is listed.
                guard Self.namesABurialGround(name) else { continue }

                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                // The surveyed cemetery is listed on its own, not as a stranger.
                // Distance alone is not enough: Apple's pin for a village burial
                // ground can sit a few hundred metres off the gate the survey
                // was taken at, so the name is checked too.
                // Every cemetery the app already knows is listed on its own, not
                // as a stranger.
                let alreadyKnown = zip(surveyedLocations, surveyed).contains { known, site in
                    location.distance(from: known) <= 200 || Self.isSamePlace(name, as: site.name)
                }
                guard !alreadyKnown else { continue }

                let distance = location.distance(from: origin)
                guard distance <= Self.radius else { continue }

                let key = String(format: "%.4f,%.4f", coordinate.latitude, coordinate.longitude)
                found[key] = NearbyPlace(
                    id: key,
                    name: name,
                    locality: item.placemark.locality ?? item.placemark.subLocality ?? "",
                    coordinate: coordinate,
                    distance: distance
                )
            }
        }

        guard anySucceeded else {
            state = .unavailable
            lastSearchCentre = nil      // try again on the next position update
            return
        }

        state = .ready(Array(found.values.sorted { $0.distance < $1.distance }.prefix(12)))
    }
}

extension NearbyCemeteries {
    /// A typed search with no radius at all: "Jakarta", "Karet Bivak", "Tanah
    /// Kusir". Someone who has flown home for a funeral is often looking for a
    /// burial ground a thousand kilometres from where they are standing, and the
    /// 25 km ring around them is exactly the wrong place to look.
    ///
    /// The region is a bias, not a fence, so results come back from wherever the
    /// words match best.
    static func searchAnywhere(term: String, from origin: CLLocationCoordinate2D) async -> [NearbyPlace] {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else { return [] }

        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        var found: [String: NearbyPlace] = [:]

        func collect(_ items: [MKMapItem]) {
            for item in items {
                guard let coordinate = item.placemark.location?.coordinate else { continue }
                let name = item.name ?? item.placemark.name ?? ""
                guard namesABurialGround(name) else { continue }
                let key = String(format: "%.4f,%.4f", coordinate.latitude, coordinate.longitude)
                guard found[key] == nil else { continue }
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                found[key] = NearbyPlace(
                    id: key,
                    name: name,
                    locality: item.placemark.locality ?? item.placemark.subLocality
                        ?? item.placemark.administrativeArea ?? "",
                    coordinate: coordinate,
                    distance: location.distance(from: here)
                )
            }
        }

        func search(_ phrase: String, around centre: CLLocationCoordinate2D, span: CLLocationDegrees) async -> [MKMapItem] {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = phrase
            request.region = MKCoordinateRegion(
                center: centre,
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
            request.resultTypes = [.pointOfInterest, .address]
            return (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
        }

        // 1. The words as typed — this is what finds "TPU Karet Bivak" or
        //    "Setra Kauh" when someone knows the name of the place itself.
        let direct = await search(query, around: origin, span: 20)
        collect(direct)

        // 2. Then treat the words as a place name. MapKit's region is a bias and
        //    not a fence, so asking for "pemakaman" from Bali keeps answering
        //    with Bali; the fix is to find where "Jakarta" is first, and ask
        //    again from there.
        var focus = direct.first?.placemark.location?.coordinate
        if focus == nil {
            focus = await search(query, around: origin, span: 40).first?.placemark.location?.coordinate
        }

        if let focus, CLLocation(latitude: focus.latitude, longitude: focus.longitude)
            .distance(from: here) > 1_000 {
            for keyword in queries {
                collect(await search("\(keyword) \(query)", around: focus, span: 0.35))
                collect(await search(keyword, around: focus, span: 0.35))
            }
        } else {
            for keyword in queries {
                collect(await search("\(keyword) \(query)", around: origin, span: 20))
            }
        }

        return Array(found.values.sorted { $0.distance < $1.distance }.prefix(20))
    }
}

struct NearbyPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let locality: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance

    static func == (lhs: NearbyPlace, rhs: NearbyPlace) -> Bool { lhs.id == rhs.id }

    /// Hundreds of metres up close, one decimal to ten kilometres, whole
    /// kilometres beyond that. The same rule as everywhere else: no precision
    /// the source does not carry.
    var distanceText: String {
        if distance >= 10_000 {
            return "\(Int((distance / 1_000).rounded())) km"
        }
        if distance >= 1_000 {
            return String(format: "%.1f km", distance / 1_000)
        }
        return "\(Int((distance / 100).rounded()) * 100) m"
    }

    func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
