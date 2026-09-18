import Foundation
import SwiftData

// Every property carries a default and there are no relationships, so these
// models stay valid if the store is ever moved to CloudKit (PRD §13). Uniqueness
// is enforced in code, not with @Attribute(.unique), for the same reason.

@Model
final class SavedGrave {
    var graveID: String = ""
    var savedAt: Date = Date.now

    init(graveID: String = "", savedAt: Date = .now) {
        self.graveID = graveID
        self.savedAt = savedAt
    }
}

/// One post on a grave's wall.
///
/// **One type, not two.** A visit and a story are the same impulse with
/// different fields filled in, and splitting them reintroduces exactly the
/// two-surfaces problem that got private notes removed: two composers, two sets
/// of rules, two explanations.
///
/// `visitedInPerson` is a *fact about the post*, written by the app at the
/// moment of writing, from the phone's own position. It is never offered as a
/// field — presence is verified, never claimed.
@Model
final class WallPostRecord {
    var id: String = UUID().uuidString
    var graveID: String = ""
    var authorName: String = ""
    var relationship: String = ""
    var body: String = ""
    var postedAt: Date = Date.now
    /// True when this was written standing at the grave.
    var visitedInPerson: Bool = false
    /// Only meaningful on a visit: a real kamboja, scattered.
    var leftFlowers: Bool = false
    /// Post-moderation: a post is visible the moment it is made, and the
    /// steward may take it down afterwards.
    var approvalRaw: String = Memory.Approval.approved.rawValue
    /// False until CloudKit has it. Everything is written to the phone first, so
    /// a cemetery with no signal still records the visit.
    var synced: Bool = false

    var approval: Memory.Approval {
        get { Memory.Approval(rawValue: approvalRaw) ?? .approved }
        set { approvalRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        graveID: String = "",
        authorName: String = "",
        relationship: String = "",
        body: String = "",
        postedAt: Date = .now,
        visitedInPerson: Bool = false,
        leftFlowers: Bool = false,
        approvalRaw: String = Memory.Approval.approved.rawValue,
        synced: Bool = false
    ) {
        self.id = id
        self.graveID = graveID
        self.authorName = authorName
        self.relationship = relationship
        self.body = body
        self.postedAt = postedAt
        self.visitedInPerson = visitedInPerson
        self.leftFlowers = leftFlowers
        self.approvalRaw = approvalRaw
        self.synced = synced
    }
}

/// The family's choice about who may read a grave's wall, made on this device.
@Model
final class WallSetting {
    var graveID: String = ""
    var visibilityRaw: String = WallVisibility.open.rawValue

    init(graveID: String = "", visibilityRaw: String = WallVisibility.open.rawValue) {
        self.graveID = graveID
        self.visibilityRaw = visibilityRaw
    }
}

/// The first immediate-family claimant becomes steward (PRD §10).
@Model
final class StewardClaim {
    var graveID: String = ""
    var stewardName: String = ""
    var claimedAt: Date = Date.now

    init(graveID: String = "", stewardName: String = "", claimedAt: Date = .now) {
        self.graveID = graveID
        self.stewardName = stewardName
        self.claimedAt = claimedAt
    }
}

/// Survey rows captured in the hidden field-capture mode (PRD §14).
@Model
final class SurveyRecord {
    var id: String = UUID().uuidString
    var name: String = ""
    var section: String = "A"
    var row: Int = 1
    var plot: Int = 1
    var latitude: Double = 0
    var longitude: Double = 0
    var accuracy: Double = 0
    var landmark: String = ""
    var deathDate: String = ""
    /// Empty means the survey could not confirm it — never guessed.
    var religion: String = ""
    var fatherName: String = ""
    var gender: String = ""
    var photoData: Data? = nil
    /// Only where the family offered one.
    var portraitData: Data? = nil
    var capturedAt: Date = Date.now

    init(id: String = UUID().uuidString, name: String = "", section: String = "A", row: Int = 1, plot: Int = 1, latitude: Double = 0, longitude: Double = 0, accuracy: Double = 0, landmark: String = "", deathDate: String = "", religion: String = "", fatherName: String = "", gender: String = "", photoData: Data? = nil, portraitData: Data? = nil, capturedAt: Date = .now) {
        self.id = id
        self.name = name
        self.section = section
        self.row = row
        self.plot = plot
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.landmark = landmark
        self.deathDate = deathDate
        self.religion = religion
        self.fatherName = fatherName
        self.gender = gender
        self.photoData = photoData
        self.portraitData = portraitData
        self.capturedAt = capturedAt
    }
}
