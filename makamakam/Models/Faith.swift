import Foundation

/// The religion recorded for a grave.
///
/// This decides which guidance the Tend screen offers, because the rite belongs
/// to the person buried there, not to whoever is holding the phone. A friend of
/// another faith — or none — standing at a Muslim grave should be shown what is
/// said at a Muslim grave.
///
/// `unrecorded` is a real and common state, not a failure: a customary-village
/// cemetery keeps a paper ledger, and the survey records only what it can
/// confirm. It is never inferred from a name.
enum Faith: String, CaseIterable, Identifiable {
    case islam
    case hindu
    case kristen
    case katolik
    case buddha
    case konghucu
    case other
    case unrecorded

    var id: String { rawValue }

    init(recorded: String?) {
        guard let recorded = recorded?.trimmingCharacters(in: .whitespaces).lowercased(),
              !recorded.isEmpty else {
            self = .unrecorded
            return
        }
        self = Faith(rawValue: recorded) ?? .other
    }

    /// Which set of texts this faith maps to. Only two are bundled; everything
    /// else lands on `umum`, which shows no text rather than the wrong text.
    var tradition: Tradition {
        switch self {
        case .islam: return .islam
        case .hindu: return .hindu
        default: return .umum
        }
    }

    var isRecorded: Bool { self != .unrecorded }

    var labelKey: S {
        switch self {
        case .islam: return .faithIslam
        case .hindu: return .faithHindu
        case .kristen: return .faithKristen
        case .katolik: return .faithKatolik
        case .buddha: return .faithBuddha
        case .konghucu: return .faithKonghucu
        case .other: return .faithOther
        case .unrecorded: return .faithUnrecorded
        }
    }
}
