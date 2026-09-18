import Foundation
import Observation

/// Who is holding the phone. Stored on the device, asked for once, never sent
/// anywhere. A shared memory has to be attributable to a person (PRD §15), so
/// the name is required before writing one — not before searching.
@Observable
final class Identity {
    var name: String {
        didSet { UserDefaults.standard.set(name, forKey: Keys.name) }
    }
    /// Free text, in the writer's own words: "teman sekolah", "tetangga lama".
    var relationship: String {
        didSet { UserDefaults.standard.set(relationship, forKey: Keys.relationship) }
    }
    /// Immediate family can claim a grave and become its steward (PRD §10).
    var isImmediateFamily: Bool {
        didSet { UserDefaults.standard.set(isImmediateFamily, forKey: Keys.family) }
    }
    /// Prayer text is selectable by tradition; the prototype site is Muslim but
    /// Bali is not uniformly so (PRD §9).
    var tradition: String {
        didSet { UserDefaults.standard.set(tradition, forKey: Keys.tradition) }
    }

    private enum Keys {
        static let name = "identity.name"
        static let relationship = "identity.relationship"
        static let family = "identity.isImmediateFamily"
        static let tradition = "identity.tradition"
    }

    init() {
        let defaults = UserDefaults.standard
        name = defaults.string(forKey: Keys.name) ?? ""
        relationship = defaults.string(forKey: Keys.relationship) ?? ""
        isImmediateFamily = defaults.bool(forKey: Keys.family)
        tradition = defaults.string(forKey: Keys.tradition) ?? Tradition.islam.rawValue
    }

    var isNamed: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var displayName: String {
        isNamed ? name : "Tanpa nama"
    }
}

enum Tradition: String, CaseIterable, Identifiable {
    case islam
    case hindu
    case umum

    var id: String { rawValue }

    func label(_ lang: Lang) -> String {
        switch self {
        case .islam: return lang.t(.traditionIslam)
        case .hindu: return lang.t(.traditionHindu)
        case .umum: return lang.t(.traditionNone)
        }
    }
}
