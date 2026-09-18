import Foundation
import CoreLocation

/// A grave record from the field survey. Read-only seed data.
///
/// The coordinate's job and the identity's job are kept apart (PRD §8): the
/// coordinate is a destination to walk toward, `section`/`row`/`plot` is which
/// grave this actually is, and the landmark bridges the last few metres that
/// GPS cannot.
struct Grave: Identifiable, Codable, Hashable {
    let id: String
    /// Which burial ground this lies in. Nil means the one the app was built
    /// with, which is how every bundled record reads.
    let cemeteryId: String?
    let name: String
    let birthYear: Int?
    let deathDate: String?      // ISO yyyy-MM-dd, as written on the stone
    /// A ledger reference, when one exists.
    ///
    /// Optional, because the layout no longer depends on it and plenty of graves
    /// have no such number — at the prototype site the stones are not in rows at
    /// all. It is how a pengurus refers to a grave, not how the app finds one,
    /// so it appears on the grave's own screen and nowhere that matters.
    let section: String?
    let row: Int?
    let plot: Int?
    let latitude: Double
    let longitude: Double
    /// Metres east and north of the cemetery's origin — the gate.
    ///
    /// This is what the plan is drawn from, and why it can be trusted: offsets
    /// come from a tape measure, so they are accurate to centimetres relative to
    /// each other. The coordinate carries GPS error; the offsets do not, and the
    /// whole plot shares one error rather than each grave carrying its own.
    /// Nil where a survey only managed a coordinate, in which case the position
    /// is projected from `latitude`/`longitude` instead.
    let x: Double?
    let y: Double?
    /// Which way this stone lies, degrees true. Nil falls back to the
    /// cemetery's own figure — no grave is drawn at an angle nobody measured.
    let bearing: Double?
    let headstonePhoto: String?
    let landmark: String
    /// What the family recorded at burial. Nil where the survey could not
    /// confirm it — never guessed from a name, which in Bali would be wrong
    /// often enough to matter.
    let religion: String?
    /// The father's name as the stone gives it, without the bin/binti — the app
    /// adds that from `gender`, so one field serves "bin", "binti" and the
    /// non-Muslim forms.
    let fatherName: String?
    /// "m", "f", or nil where the survey did not record it.
    let gender: String?
    /// Photographs from the survey: the headstone, and the person if the family
    /// offered one. Empty is the normal state until a survey has run.
    let photos: [GravePhoto]?
    let verified: Bool
    /// The family member who claimed this grave. Approves and removes shared
    /// memories. Nil means nobody has claimed it yet.
    let stewardName: String?
    /// The life of the person, written by the family in Markdown and edited in
    /// the admin panel. Nil until somebody writes one — a grave with no profile
    /// is the ordinary case, not an empty slot to be filled.
    let profileMarkdown: String?
    /// Who may see the wall: "open", "family", "closed". Some families will not
    /// want a wall at all, and that must be their call (PRD §10).
    let wallVisibility: String?

    var wall: WallVisibility {
        WallVisibility(rawValue: wallVisibility ?? "") ?? .open
    }

    var faith: Faith {
        Faith(recorded: religion)
    }

    var photoList: [GravePhoto] { photos ?? [] }

    /// Where to draw this grave, in metres from the gate. Surveyed offsets when
    /// they exist, otherwise the coordinate projected onto the same local grid —
    /// so a cemetery recorded either way still plots.
    func localPosition(origin: Site) -> (x: Double, y: Double) {
        if let x, let y { return (x, y) }
        return Geo.localOffset(of: coordinate, from: origin.coordinate)
    }

    /// "binti Sulaiman", "bin Hamzah", or "putri dari Nyoman Kertia" where the
    /// Arabic form would not belong. Nil when the name on the stone already
    /// carries it, so it is never printed twice.
    func parentageLine(_ lang: Lang) -> String? {
        guard let fatherName, !fatherName.isEmpty else { return nil }
        let lowered = name.lowercased()
        guard !lowered.contains(" bin "), !lowered.contains(" binti ") else { return nil }

        let key: S
        switch (faith, gender?.lowercased()) {
        case (.islam, "f"): key = .parentageBinti
        case (.islam, "m"): key = .parentageBin
        case (_, "f"):      key = .parentageDaughter
        case (_, "m"):      key = .parentageSon
        default:            key = .parentageChild
        }
        return lang.t(key, fatherName)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// "Blok A · Baris 2 · Petak 3", or nothing at all.
    func plotLabel(_ lang: Lang) -> String? {
        var parts: [String] = []
        if let section { parts.append(lang.t(.plotBlock, section)) }
        if let row { parts.append(lang.t(.plotRow, row)) }
        if let plot { parts.append(lang.t(.plotPlot, plot)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// "A-2-3" for a picker or a log line. Falls back to the record's own id.
    var shortPlotLabel: String {
        guard let section, let row, let plot else { return id }
        return "\(section)-\(row)-\(plot)"
    }

    var deathDateValue: Date? {
        guard let deathDate else { return nil }
        return Self.isoDay.date(from: deathDate)
    }

    /// "1955 – 2023", or just the year of death when a birth year is unknown.
    func yearsLine(_ lang: Lang) -> String {
        let death = deathDate.map { String($0.prefix(4)) }
        switch (birthYear, death) {
        case let (b?, d?): return "\(b) – \(d)"
        case let (nil, d?): return lang.t(.died, d)
        case let (b?, nil): return lang.t(.born, String(b))
        default: return ""
        }
    }

    func deathDateLine(_ lang: Lang) -> String? {
        guard let date = deathDateValue else { return nil }
        return lang.day(date)
    }

    static let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Makassar")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

}

/// The surveyed cemetery. One site for the prototype.
/// One photograph attached to a grave.
struct GravePhoto: Codable, Hashable, Identifiable {
    enum Kind: String, Codable {
        /// The headstone, for confirming you are at the right plot.
        case headstone
        /// The person, if the family offered one. Never required: plenty of
        /// families have no photograph, and the app must not imply a gap.
        case person
        /// The burial ground itself — the gate, the path in, the view a visitor
        /// would recognise from the road.
        case cemetery
    }

    let id: String
    let kind: Kind
    /// An asset name in the bundle, or a file name in the app's documents
    /// directory for anything the survey captured on this device.
    let source: String
    let caption: String?
}

/// A surveyed cemetery. There may be several.
struct Site: Codable, Hashable, Identifiable {
    /// The record name in CloudKit, or the id the bundle gives it.
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    /// How close you must be for the place to count as "here".
    let radiusMeters: Double
    let surveyedSection: String
    let rows: Int
    let plotsPerRow: Int
    /// Which way the graves lie, in degrees true. Used to draw them as the
    /// oblongs they are rather than as dots.
    let graveBearing: Double?
    /// The wall, as corner offsets in metres from the gate. The strongest cue on
    /// the plan — people match a shape, not a pin — and nil until somebody walks
    /// the perimeter.
    let boundary: [[Double]]?
    /// Photographs of the burial ground. Bundled ones come from the survey;
    /// anything captured on this device is added at runtime.
    let photos: [GravePhoto]?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

/// A memory written by the outer circle and read by the family.
///
/// Seeded ones arrive from JSON with earlier timestamps; ones written in the app
/// are stored in SwiftData and mapped into this shape for display.
struct Memory: Identifiable, Hashable {
    let id: String
    let graveID: String
    let authorName: String
    let relationship: String
    let body: String
    let writtenAt: Date
    let approval: Approval

    enum Approval: String, Codable {
        case pending    // waiting for the steward
        case approved
        case removed
    }
}

struct SeedMemory: Codable {
    let id: String
    let graveID: String
    let authorName: String
    let relationship: String
    let body: String
    let writtenAt: Date
}

/// A recorded visit: who came, when, and whether they left a real kamboja.
struct Visit: Identifiable, Hashable {
    let id: String
    let graveID: String
    let visitorName: String
    let date: Date
    let leftFlower: Bool
}

struct SeedVisit: Codable {
    let id: String
    let graveID: String
    let visitorName: String
    let date: Date
    let leftFlower: Bool
}

struct SeedFile: Codable {
    let site: Site
    let graves: [Grave]
    let memories: [SeedMemory]
    let visits: [SeedVisit]
}
