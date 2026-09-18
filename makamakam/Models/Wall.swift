import Foundation

/// Who may read the wall.
enum WallVisibility: String, CaseIterable, Identifiable {
    /// Anyone who finds the grave.
    case open
    /// Only the family who holds the record.
    case family
    /// Nobody. Some families do not want a wall, and the product has to be able
    /// to take no for an answer (PRD §10).
    case closed

    var id: String { rawValue }

    var labelKey: S {
        switch self {
        case .open: return .wallOpen
        case .family: return .wallFamilyOnly
        case .closed: return .wallClosed
        }
    }

    var noteKey: S {
        switch self {
        case .open: return .wallOpenNote
        case .family: return .wallFamilyOnlyNote
        case .closed: return .wallClosedNote
        }
    }
}

/// One entry on the wall.
///
/// The wall replaces three separate lists — visits, flowers and memories — with
/// the thing they always were: what has happened at this grave, in the order it
/// happened. Nothing is ever counted or ranked; a timeline says "this happened",
/// a total says "somebody is winning" (PRD §6).
struct WallEntry: Identifiable, Hashable {
    let id: String
    let graveID: String
    let authorName: String
    let relationship: String
    let body: String?
    let postedAt: Date
    /// Verified at the moment of writing, never claimed by the writer.
    let visitedInPerson: Bool
    let leftFlowers: Bool
    let approval: Memory.Approval
}
