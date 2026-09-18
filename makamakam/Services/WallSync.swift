import Foundation
import CloudKit

/// The wall, shared.
///
/// A story written on a friend's phone has to reach the family's phone, or the
/// pillar does not exist. Posts go to the public database, which is also the
/// honest place for them: they were written to be read by the family and by
/// other visitors.
///
/// **Moderation cannot be a field on the post.** CloudKit's public database lets
/// a person edit only what they created, so a steward can never write to a
/// stranger's record. A decision is therefore its own record, made by the
/// steward, and the app applies the latest decision it can find for each post.
/// That is also closer to the truth: the post is what somebody said, and the
/// decision is what the family did about it.
enum WallSync {
    static var isAvailable: Bool { RemoteCatalog.isAvailable }

    private static var database: CKDatabase {
        CKContainer(identifier: RemoteCatalog.containerIdentifier).publicCloudDatabase
    }

    struct RemotePost {
        let id: String
        let graveID: String
        let authorName: String
        let relationship: String
        let isVisit: Bool
        let leftFlowers: Bool
        let body: String?
        let postedAt: Date
    }

    struct RemoteDecision {
        let postID: String
        let approval: Memory.Approval
        let decidedAt: Date
    }

    // MARK: Reading

    static func fetch() async throws -> (posts: [RemotePost], decisions: [RemoteDecision]) {
        guard isAvailable else { return ([], []) }
        async let postRecords = records(ofType: "WallPost")
        async let decisionRecords = records(ofType: "WallDecision")
        let (posts, decisions) = try await (postRecords, decisionRecords)

        return (
            posts.map { record in
                RemotePost(
                    id: record.recordID.recordName,
                    graveID: record["graveID"] as? String ?? "",
                    authorName: record["authorName"] as? String ?? "",
                    relationship: record["relationship"] as? String ?? "",
                    isVisit: (record["isVisit"] as? Int ?? 0) == 1,
                    leftFlowers: (record["leftFlowers"] as? Int ?? 0) == 1,
                    body: (record["body"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    postedAt: record["postedAt"] as? Date ?? .now
                )
            },
            decisions.compactMap { record in
                guard let postID = record["postID"] as? String,
                      let raw = record["approval"] as? String,
                      let approval = Memory.Approval(rawValue: raw) else { return nil }
                return RemoteDecision(
                    postID: postID,
                    approval: approval,
                    decidedAt: record["decidedAt"] as? Date ?? .now
                )
            }
        )
    }

    private static func records(ofType type: String) async throws -> [CKRecord] {
        var found: [CKRecord] = []
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        var response = try await database.records(matching: query, resultsLimit: 200)
        found += response.matchResults.compactMap { try? $0.1.get() }
        while let cursor = response.queryCursor {
            response = try await database.records(continuingMatchFrom: cursor, resultsLimit: 200)
            found += response.matchResults.compactMap { try? $0.1.get() }
        }
        return found
    }

    // MARK: Writing

    /// Sends one post. The record name is the local id, so a post that is sent
    /// twice overwrites itself rather than appearing twice.
    static func send(
        id: String,
        graveID: String,
        authorName: String,
        relationship: String,
        isVisit: Bool,
        leftFlowers: Bool,
        body: String?,
        postedAt: Date
    ) async throws {
        guard isAvailable else { return }
        let record = CKRecord(recordType: "WallPost", recordID: CKRecord.ID(recordName: id))
        record["graveID"] = graveID as CKRecordValue
        record["authorName"] = authorName as CKRecordValue
        record["relationship"] = relationship as CKRecordValue
        record["isVisit"] = (isVisit ? 1 : 0) as CKRecordValue
        record["leftFlowers"] = (leftFlowers ? 1 : 0) as CKRecordValue
        record["body"] = (body ?? "") as CKRecordValue
        record["postedAt"] = postedAt as CKRecordValue
        _ = try await database.save(record)
    }

    /// The steward's decision about somebody else's post.
    static func decide(
        postID: String,
        graveID: String,
        approval: Memory.Approval,
        by steward: String
    ) async throws {
        guard isAvailable else { return }
        // One decision per steward per post, so changing their mind replaces
        // the decision rather than stacking another on top.
        let name = "decision-\(postID)"
        let record = CKRecord(recordType: "WallDecision", recordID: CKRecord.ID(recordName: name))
        record["postID"] = postID as CKRecordValue
        record["graveID"] = graveID as CKRecordValue
        record["approval"] = approval.rawValue as CKRecordValue
        record["decidedBy"] = steward as CKRecordValue
        record["decidedAt"] = Date.now as CKRecordValue
        _ = try await database.save(record)
    }

    /// Whether this phone can write at all. The shared database still needs an
    /// iCloud account behind it, and plenty of phones in a cemetery will not
    /// have one signed in.
    static func canWrite() async -> Bool {
        await accountStatus() == .available
    }

    static func accountStatus() async -> CKAccountStatus {
        guard isAvailable else { return .couldNotDetermine }
        return (try? await CKContainer(identifier: RemoteCatalog.containerIdentifier).accountStatus())
            ?? .couldNotDetermine
    }
}

/// What CloudKit last said about the walls, kept so a cemetery with no signal
/// still shows what it showed yesterday.
enum WallCache {
    struct Snapshot: Codable {
        struct Post: Codable {
            let id: String
            let graveID: String
            let authorName: String
            let relationship: String
            let isVisit: Bool
            let leftFlowers: Bool
            let body: String?
            let postedAt: Date
        }
        struct Decision: Codable {
            let postID: String
            let approval: String
            let decidedAt: Date
        }
        var posts: [Post]
        var decisions: [Decision]
        var fetchedAt: Date
    }

    private static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("wall-cache.json")
    }

    static func read() -> Snapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    static func write(_ snapshot: Snapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url)
    }
}
