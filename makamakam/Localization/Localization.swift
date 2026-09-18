import Foundation
import Observation

enum LanguageCode: String, CaseIterable, Identifiable {
    case id
    case en

    var id_: String { rawValue }
    var id: String { rawValue }

    var label: String {
        switch self {
        case .id: return "Bahasa Indonesia"
        case .en: return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .id: return Locale(identifier: "id_ID")
        case .en: return Locale(identifier: "en_GB")
        }
    }
}

/// The interface language, chosen by the person rather than fixed to the device.
///
/// A cemetery in Tuban gets grandchildren home from Jakarta, in-laws from
/// Australia, and Javanese migrants who read neither comfortably in a hurry.
/// The first launch follows the device; after that it is theirs to set.
@Observable
final class Lang {
    var code: LanguageCode {
        didSet { UserDefaults.standard.set(code.rawValue, forKey: Self.key) }
    }

    private static let key = "app.language"

    init() {
        if let forced = Demo.language {
            code = forced
            return
        }
        if let stored = UserDefaults.standard.string(forKey: Self.key),
           let value = LanguageCode(rawValue: stored) {
            code = value
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            code = preferred.hasPrefix("id") ? .id : .en
        }
    }

    var locale: Locale { code.locale }

    func callAsFunction(_ key: S) -> String { t(key) }

    func t(_ key: S) -> String {
        let pair = Strings.table[key] ?? (id: key.rawValue, en: key.rawValue)
        return code == .id ? pair.id : pair.en
    }

    func t(_ key: S, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: locale, arguments: arguments)
    }

    /// Dates in the reader's language, in Bali's time zone — the time zone of the
    /// place the record is about, not of wherever the reader happens to be.
    func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "Asia/Makassar")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
