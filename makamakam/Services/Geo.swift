import Foundation
import CoreLocation

enum Geo {
    /// Initial bearing from one coordinate to another, in degrees true.
    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return normalize(atan2(y, x) * 180 / .pi)
    }

    /// Wraps any angle into 0..<360.
    static func normalize(_ degrees: Double) -> Double {
        let d = degrees.truncatingRemainder(dividingBy: 360)
        return d < 0 ? d + 360 : d
    }

    /// Shortest signed turn from `a` to `b`, in -180...180. Handling 359°→1°
    /// explicitly is what stops the arrow taking the long way round (PRD §12).
    static func delta(from a: Double, to b: Double) -> Double {
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    /// Low-pass filter that respects the wraparound.
    static func smooth(previous: Double, next: Double, factor: Double = 0.18) -> Double {
        normalize(previous + delta(from: previous, to: next) * factor)
    }

    /// Metres east and north of an origin. A flat-earth projection, which over
    /// a burial ground a hundred metres across is accurate to well under the
    /// width of a grave.
    static func localOffset(of coordinate: CLLocationCoordinate2D,
                            from origin: CLLocationCoordinate2D) -> (x: Double, y: Double) {
        let metresPerDegreeLat = 110_574.0
        let metresPerDegreeLon = 111_320.0 * cos(origin.latitude * .pi / 180)
        return (
            x: (coordinate.longitude - origin.longitude) * metresPerDegreeLon,
            y: (coordinate.latitude - origin.latitude) * metresPerDegreeLat
        )
    }

    /// A coordinate `metres` away from `origin` on `bearing` degrees true.
    /// Used by the simulated walk, and by nothing the user ever sees.
    static func coordinate(from origin: CLLocationCoordinate2D, bearing: Double, metres: Double) -> CLLocationCoordinate2D {
        let metresPerDegreeLat = 110_574.0
        let metresPerDegreeLon = 111_320.0 * cos(origin.latitude * .pi / 180)
        let rad = bearing * .pi / 180
        return CLLocationCoordinate2D(
            latitude: origin.latitude + (metres * cos(rad)) / metresPerDegreeLat,
            longitude: origin.longitude + (metres * sin(rad)) / metresPerDegreeLon
        )
    }
}

enum Phase {
    /// Still walking. One arrow, one distance.
    case approach
    /// Close enough that GPS has nothing left to say. Look up instead.
    case arrive

    /// Where the arrow stops being worth following.
    ///
    /// Not a fixed distance, and not read off the accuracy figure either. What
    /// matters is how wrong the arrow's *direction* becomes as the distance
    /// closes: with a combined error `e` at distance `d`, the angular error is
    /// `atan(e / d)` — about 6° at 30 m and 45° at 3 m for a 3 m error. The
    /// arrow does not decay gently; it falls off a cliff.
    ///
    /// Three things make the real error larger than the number on screen:
    /// the surveyed coordinate carries its own error on top of the visitor's, so
    /// two independent 3 m errors combine to about 4.2 m; `horizontalAccuracy`
    /// is a 68% radius, so roughly one reading in three is worse than it claims;
    /// and the quoted figures are open-sky, while this site has kamboja
    /// throughout, a boundary wall and stones — exactly what degrades GNSS.
    ///
    /// So: hand over where the direction error would exceed 20°. That puts the
    /// handoff near 6 m rather than the 8 m guessed in v3, clamped to 5–15 m so
    /// good GPS keeps the arrow alive longer and poor GPS gives up sooner.
    static func handoffDistance(
        userAccuracy: CLLocationAccuracy,
        graveAccuracy: CLLocationAccuracy
    ) -> Double {
        let combined = hypot(max(userAccuracy, 1), max(graveAccuracy, 1))
        let raw = combined / tan(20 * .pi / 180)
        return min(max(raw, 5), 15)
    }

    /// The angle the arrow may be wrong by before it is no longer worth
    /// following. Everything above derives from this one number.
    static let angularCeiling: Double = 20

    /// How accurate the survey's own coordinates are. A tape-measured offset
    /// from an averaged origin is good to centimetres in *relative* terms, but
    /// the origin itself was a phone standing at a gate.
    static let surveyAccuracy: CLLocationAccuracy = 3

    /// Which phase a distance falls in, against a threshold that now changes
    /// with the signal.
    static func phase(for metres: Double, handoff: Double) -> Phase {
        metres <= handoff ? .arrive : .approach
    }

    /// The light tap on the way in, kept proportional to the handoff rather than
    /// fixed, so the two do not cross on a bad day.
    static func nearThreshold(handoff: Double) -> Double { handoff * 2.5 }
}

enum Distance {
    /// Never show precision you don't have (PRD §12): whole metres above 20 m,
    /// 5 m increments below.
    static func text(_ metres: Double) -> String {
        if metres.isNaN || metres < 0 { return "—" }
        if metres > 20 {
            return "\(Int(metres.rounded())) m"
        }
        let stepped = max(5, (metres / 5).rounded() * 5)
        return "\(Int(stepped)) m"
    }

    /// A distance somebody might travel, rather than one they might pace out:
    /// hundreds of metres up close, one decimal to ten kilometres, whole
    /// kilometres beyond. Never more precision than the reason for saying it.
    static func journeyText(_ metres: Double) -> String {
        if metres >= 10_000 { return "\(Int((metres / 1_000).rounded())) km" }
        if metres >= 1_000 { return String(format: "%.1f km", metres / 1_000) }
        return "\(max(50, Int((metres / 50).rounded()) * 50)) m"
    }

    /// The honest line about what the phone actually knows. Accuracy does not
    /// improve as you approach, so this is stated plainly rather than hidden
    /// behind a confidence animation (PRD §7).
    static func accuracyText(_ accuracy: Double, lang: Lang) -> String {
        guard accuracy > 0 else { return lang.t(.approachAccuracyUnknown) }
        return lang.t(.approachAccuracy, Int(accuracy.rounded()))
    }
}
