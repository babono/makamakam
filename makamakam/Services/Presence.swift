import Foundation
import CoreLocation
import Observation

/// Words travel. Acts don't (PRD §3).
///
/// Everything that is an act — scattering a flower, praying at the plot, reading
/// what other people left — asks this type whether there is a body in the place.
@Observable
final class Presence {
    private let location: LocationService
    private let store: GraveStore

    /// Field-mode override: treats the person as standing in the cemetery.
    ///
    /// The presence locks are the point of this product, so this exists only
    /// behind the hidden field sheet, for testing and for rehearsing a demo away
    /// from Bali. Every screen it affects says that it is on.
    var pretendPresent: Bool {
        didSet { UserDefaults.standard.set(pretendPresent, forKey: Self.key) }
    }

    private static let key = "debug.pretendPresent"

    init(location: LocationService, store: GraveStore) {
        self.location = location
        self.store = store
        self.pretendPresent = Demo.pretendsPresent || UserDefaults.standard.bool(forKey: Self.key)
    }

    /// Inside the cemetery. Deliberately generous: the gate is about being here,
    /// not about standing on an exact spot GPS could never resolve anyway.
    /// Inside *a* surveyed cemetery — there may be more than one.
    var atSite: Bool {
        if pretendPresent { return true }
        return currentSite != nil
    }

    /// Which cemetery the reader is standing in, if any.
    var currentSite: Site? {
        guard let here = location.location else { return nil }
        return store.cemeteries.first { here.distance(from: $0.location) <= $0.radiusMeters }
    }

    func isAt(_ site: Site) -> Bool {
        if pretendPresent { return true }
        guard let here = location.location else { return false }
        return here.distance(from: site.location) <= site.radiusMeters
    }

    /// Near one particular grave — used only for the flower and the visit record,
    /// where "at this grave" is the claim being made.
    func atGrave(_ grave: Grave) -> Bool {
        if pretendPresent { return true }
        guard let here = location.location else { return false }
        return here.distance(from: grave.location) <= 25
    }

    var locationIsKnown: Bool { location.location != nil }

    /// How far the person is from the nearest surveyed cemetery.
    var metresFromSite: Double? {
        guard let here = location.location else { return nil }
        return store.cemeteries.map { here.distance(from: $0.location) }.min()
    }

    func metres(from site: Site) -> Double? {
        location.location?.distance(from: site.location)
    }

    var authorizationDenied: Bool {
        location.authorization == .denied || location.authorization == .restricted
    }
}
