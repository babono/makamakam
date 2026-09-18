import Foundation
import CloudKit
import SwiftData
import Observation

/// The graves a person keeps, in their own half of the container.
///
/// The **private** database, not the public one — and the distinction is the
/// whole point. Both live in `iCloud.me.babono.makamakam`; the private half is
/// scoped to one Apple ID, invisible to every other user of the app, and stored
/// against that person's own iCloud rather than the app's quota.
///
/// Which graves somebody keeps is exactly the sort of thing the outer circle is
/// careful about — the app promises "nobody is told which graves you keep", and
/// the public database would make that promise false.
///
/// SwiftData stays the working copy, so the list is there with the radio off and
/// on a phone with no Apple ID at all. A full iCloud costs sync and nothing else.
@Observable
final class SavedSync {
    private(set) var isSyncing = false
    private(set) var lastSyncFailed = false

    private var database: CKDatabase {
        CKContainer(identifier: RemoteCatalog.containerIdentifier).privateCloudDatabase
    }

    private static let recordType = "SavedGrave"

    /// Pushes what this phone has kept, then takes back whatever the account
    /// knows. A grave kept on either side ends up on both: keeping is additive,
    /// and the one destructive act — letting go of a grave — is handled by
    /// `forget`, so a fresh device cannot silently undo it.
    @MainActor
    func sync(context: ModelContext) async {
        guard RemoteCatalog.isAvailable, !isSyncing else { return }
        guard await WallSync.canWrite() else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let local = (try? context.fetch(FetchDescriptor<SavedGrave>())) ?? []

            for saved in local {
                let record = CKRecord(
                    recordType: Self.recordType,
                    recordID: CKRecord.ID(recordName: saved.graveID)
                )
                record["graveID"] = saved.graveID as CKRecordValue
                record["savedAt"] = saved.savedAt as CKRecordValue
                _ = try await database.save(record)
            }

            let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
            let response = try await database.records(matching: query, resultsLimit: 200)
            let remote = response.matchResults.compactMap { try? $0.1.get() }

            let known = Set(local.map(\.graveID))
            for record in remote where !known.contains(record.recordID.recordName) {
                context.insert(
                    SavedGrave(
                        graveID: record.recordID.recordName,
                        savedAt: record["savedAt"] as? Date ?? .now
                    )
                )
            }
            try? context.save()
            lastSyncFailed = false
        } catch {
            // A full iCloud, a signed-out phone, no signal: the list is already
            // on the device, so none of these are worth interrupting anyone for.
            lastSyncFailed = true
        }
    }

    /// Letting go of a grave has to reach the account, or the next sync brings
    /// it back.
    func forget(graveID: String) async {
        guard RemoteCatalog.isAvailable else { return }
        _ = try? await database.deleteRecord(withID: CKRecord.ID(recordName: graveID))
    }
}
