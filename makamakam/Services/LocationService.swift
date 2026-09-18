import Foundation
import CoreLocation
import Observation

/// Location and heading, filtered for a screen that someone reads while walking.
///
/// The simulator has no compass and no usable GPS, so the service also carries a
/// simulated walk. It is only ever enabled from the hidden developer sheet, and
/// every screen shows that it is on.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorization: CLAuthorizationStatus = .notDetermined
    var location: CLLocation?
    /// Smoothed true heading, degrees. Nil while the compass has nothing useful.
    var heading: Double?
    /// Raw CoreLocation heading accuracy; negative means invalid.
    var headingAccuracy: Double = -1
    var simulating: Bool = false

    /// Compass drift near metal is expected. Above this the arrow freezes and
    /// the landmark text takes over rather than letting it flail (PRD §12).
    private let headingAccuracyLimit: Double = 35

    var headingIsTrustworthy: Bool {
        guard heading != nil else { return false }
        if simulating { return true }
        return headingAccuracy > 0 && headingAccuracy <= headingAccuracyLimit
    }

    var horizontalAccuracy: Double {
        guard let acc = location?.horizontalAccuracy, acc > 0 else { return -1 }
        return acc
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1
        manager.headingFilter = 2
        authorization = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Starting updates is itself what raises the system prompt, so this is a
    /// no-op until someone has been asked. Searching never asks.
    func start() {
        guard !simulating else { return }
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func distance(to target: CLLocation) -> Double? {
        location.map { $0.distance(from: target) }
    }

    func bearing(to target: CLLocationCoordinate2D) -> Double? {
        location.map { Geo.bearing(from: $0.coordinate, to: target) }
    }

    /// Arrow rotation is bearing minus heading (PRD §11).
    func arrowRotation(to target: CLLocationCoordinate2D) -> Double? {
        guard let bearing = bearing(to: target), let heading else { return nil }
        return Geo.normalize(bearing - heading)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            start()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !simulating, let latest = locations.last else { return }
        location = latest
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard !simulating else { return }
        headingAccuracy = newHeading.headingAccuracy
        let raw = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        guard raw >= 0 else { return }
        heading = heading.map { Geo.smooth(previous: $0, next: raw) } ?? raw
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A dropped fix is ordinary outdoors. The UI already says what it knows.
    }

    // MARK: - Simulated walk (developer sheet only)

    private var simulationTimer: Timer?

    /// Walks the simulated position from `metres` away toward `target`, so the
    /// approach and arrival screens can be rehearsed without flying to Bali.
    func startSimulation(target: CLLocationCoordinate2D, startingMetres: Double = 60, bearingFromTarget: Double = 200) {
        stop()
        simulationTimer?.invalidate()
        simulating = true
        heading = Geo.normalize(bearingFromTarget - 180)
        headingAccuracy = 8

        var remaining = startingMetres
        let place: (Double) -> Void = { [weak self] metres in
            let coord = Geo.coordinate(from: target, bearing: bearingFromTarget, metres: max(metres, 0))
            self?.location = CLLocation(
                coordinate: coord,
                altitude: 12,
                horizontalAccuracy: 4,
                verticalAccuracy: 6,
                timestamp: .now
            )
        }
        place(remaining)

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self, self.simulating else { timer.invalidate(); return }
            remaining = max(0, remaining - 4)
            place(remaining)
            // Drift the heading a little so the smoothing is visible.
            let target = Geo.normalize(bearingFromTarget - 180 + Double.random(in: -12...12))
            self.heading = Geo.smooth(previous: self.heading ?? target, next: target, factor: 0.25)
            if remaining == 0 { timer.invalidate() }
        }
    }

    /// Stands still at one spot, rather than walking toward one. The field sheet
    /// uses it to put the reader at the cemetery gate from a desk in an office.
    func standAt(_ coordinate: CLLocationCoordinate2D, accuracy: Double = 5, heading degrees: Double = 20) {
        stop()
        simulationTimer?.invalidate()
        simulationTimer = nil
        simulating = true
        heading = degrees
        headingAccuracy = 8
        location = CLLocation(
            coordinate: coordinate,
            altitude: 12,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 6,
            timestamp: .now
        )
    }

    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        simulating = false
        location = nil
        heading = nil
        headingAccuracy = -1
        start()
    }
}
