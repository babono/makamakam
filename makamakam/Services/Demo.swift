import Foundation

/// Launch arguments that open the app on one screen.
///
/// Two uses: rehearsing a demo on stage without walking the whole flow, and
/// screenshotting each screen in the Simulator, where there is no compass and no
/// real position. Never reachable by tapping.
enum Demo {
    enum Screen: String {
        case grave, orient, approach, arrive, tend, wall, profile, settings, saved, cemetery, field, plan
    }

    static var screen: Screen? {
        #if DEBUG
        guard let raw = value(for: "-demo") else { return nil }
        return Screen(rawValue: raw)
        #else
        return nil
        #endif
    }

    static var graveID: String {
        #if DEBUG
        return value(for: "-demoGrave") ?? "A-2-03"
        #else
        return "A-2-03"
        #endif
    }

    /// Metres from the target to pin the simulated walk at.
    static var metres: Double? {
        #if DEBUG
        return value(for: "-demoMetres").flatMap(Double.init)
        #else
        return nil
        #endif
    }

    /// Grave ids to mark as kept, so the Saved tab has something in it.
    static var seededSavedGraves: [String] {
        #if DEBUG
        return (value(for: "-demoSaved") ?? "")
            .split(separator: ",")
            .map { String($0) }
        #else
        return []
        #endif
    }

    /// Treats the person as standing in the cemetery, for a screenshot run.
    static var pretendsPresent: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demoPresent")
        #else
        return false
        #endif
    }

    /// Selects the first nearby cemetery pin, for a screenshot run.
    static var selectsFirstNearbyPin: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demoSelectPin")
        #else
        return false
        #endif
    }

    /// Pre-fills the search field, for a screenshot run.
    static var search: String? {
        #if DEBUG
        return value(for: "-demoSearch")
        #else
        return nil
        #endif
    }

    /// Forces an interface language for a screenshot run.
    static var language: LanguageCode? {
        #if DEBUG
        return value(for: "-demoLang").flatMap(LanguageCode.init(rawValue:))
        #else
        return nil
        #endif
    }

    private static func value(for key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
}
