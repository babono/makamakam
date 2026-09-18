import Foundation
import CloudKit

/// The survey as the admin panel last published it.
///
/// This is a *refresh*, never a dependency. The bundled `graves.json` remains
/// the floor: rural reception is unreliable and the whole product has to work
/// with the radio off (PRD §13), so a failed fetch is not an error state worth
/// showing anybody — it simply leaves the last good data in place.
///
/// The record shape is the one `makamakam-web` writes, so the same records serve
/// the panel and the app.
enum RemoteCatalog {
    static let containerIdentifier = "iCloud.me.babono.makamakam"

    /// What the app keeps between launches: whatever CloudKit last said.
    struct Snapshot: Codable {
        var cemeteries: [Site]
        var graves: [Grave]
        var fetchedAt: Date
    }

    enum Failure: Error {
        case noCemetery
        /// The build has no CloudKit entitlement — an ordinary state for a
        /// command-line simulator build, and not worth reporting as a failure.
        case notEntitled
    }

    /// Whether this build may talk to CloudKit at all.
    ///
    /// `CKContainer(identifier:)` does not fail politely when the entitlement is
    /// missing — it traps, taking the app down. An *unsigned* build carries no
    /// entitlements, and iOS offers no public way to ask a running binary what
    /// it was signed with, so this is settled at compile time instead: build
    /// with `-D NO_CLOUDKIT` and the app runs on its bundled survey alone.
    ///
    /// Xcode signs both device and simulator builds, so the flag is only needed
    /// for command-line builds that pass `CODE_SIGNING_ALLOWED=NO`.
    static var isAvailable: Bool {
        #if NO_CLOUDKIT
        return false
        #else
        return true
        #endif
    }

    private static var database: CKDatabase {
        CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    static func fetch() async throws -> Snapshot {
        guard isAvailable else { throw Failure.notEntitled }
        async let cemeteries = records(ofType: "Cemetery")
        async let graveRecords = records(ofType: "Grave")
        async let photoRecords = records(ofType: "Photo")

        let (cemeteryRows, graveRows, photoRows) = try await (cemeteries, graveRecords, photoRecords)
        guard !cemeteryRows.isEmpty else { throw Failure.noCemetery }

        // Assets arrive as files CloudKit has already downloaded to a temporary
        // location; they are copied into Documents so the rest of the app can
        // find them by name, offline, for as long as the phone keeps them.
        let photos = photos(from: photoRows)

        let sites = cemeteryRows.map {
            site(from: $0, photos: photos[$0.recordID.recordName] ?? [])
        }
        let known = Set(sites.map(\.id))

        let graves = graveRows
            // A grave belonging to no cemetery we know about is dropped rather
            // than attached to the first one that happens to be nearby.
            .filter { known.contains(($0["cemeteryId"] as? String) ?? "") }
            .map { grave(from: $0, photos: photos[$0.recordID.recordName] ?? []) }
            // By name: a ledger number is optional now, and sorting by one that
            // half the graves lack puts them all at the front in arrival order.
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return Snapshot(cemeteries: sites, graves: graves, fetchedAt: .now)
    }

    /// Groups photograph records by what they belong to, caching each asset on
    /// the way past. A photograph that fails to copy is skipped rather than
    /// listed: a name with a broken frame under it is worse than no frame.
    private static func photos(from records: [CKRecord]) -> [String: [GravePhoto]] {
        var grouped: [String: [GravePhoto]] = [:]

        for record in records {
            guard let owner = record["ownerId"] as? String else { continue }
            let source = record["source"] as? String
                ?? "\(record.recordID.recordName).jpg"

            if let asset = record["image"] as? CKAsset,
               let fileURL = asset.fileURL {
                let destination = PhotoStore.directory.appendingPathComponent(source)
                if !FileManager.default.fileExists(atPath: destination.path) {
                    do {
                        try FileManager.default.copyItem(at: fileURL, to: destination)
                    } catch {
                        continue
                    }
                }
            } else if !FileManager.default.fileExists(
                atPath: PhotoStore.directory.appendingPathComponent(source).path
            ) {
                continue
            }

            let kind = GravePhoto.Kind(rawValue: record["kind"] as? String ?? "") ?? .headstone
            let caption = (record["caption"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            grouped[owner, default: []].append(
                GravePhoto(id: record.recordID.recordName, kind: kind, source: source, caption: caption)
            )
        }

        return grouped
    }

    /// Everything of one type, following the cursor. These are tens of records,
    /// not thousands — one cemetery at a time.
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

    // MARK: Mapping

    private static func site(from record: CKRecord, photos: [GravePhoto]) -> Site {
        let name = record["name"] as? String ?? ""
        let address = record["address"] as? String ?? ""
        let latitude = record["latitude"] as? Double ?? 0
        let longitude = record["longitude"] as? Double ?? 0
        let radius = record["radiusMeters"] as? Double ?? 120
        let section = record["surveyedSection"] as? String ?? "A"
        let rows = record["rows"] as? Int ?? 1
        let plots = record["plotsPerRow"] as? Int ?? 1
        let bearing = record["graveBearing"] as? Double

        // Corner offsets travel as a flat list of numbers, since CloudKit has no
        // nested arrays: [x1, y1, x2, y2, …].
        var boundary: [[Double]]?
        if let flat = record["boundaryOffsets"] as? [Double], flat.count >= 6 {
            boundary = stride(from: 0, to: flat.count - 1, by: 2).map { [flat[$0], flat[$0 + 1]] }
        }

        return Site(
            id: record.recordID.recordName,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radius,
            surveyedSection: section,
            rows: rows,
            plotsPerRow: plots,
            graveBearing: bearing,
            boundary: boundary,
            photos: photos
        )
    }

    private static func grave(from record: CKRecord, photos: [GravePhoto]) -> Grave {
        let name = record["name"] as? String ?? ""
        let section = record["section"] as? String
        let row = record["row"] as? Int
        let plot = record["plot"] as? Int
        let latitude = record["latitude"] as? Double ?? 0
        let longitude = record["longitude"] as? Double ?? 0
        let landmark = record["landmark"] as? String ?? ""
        // Stored as 0/1: CloudKit has no boolean.
        let verified = (record["verified"] as? Int ?? 0) == 1

        return Grave(
            id: record.recordID.recordName,
            cemeteryId: record["cemeteryId"] as? String,
            name: name,
            birthYear: record["birthYear"] as? Int,
            deathDate: record["deathDate"] as? String,
            section: section,
            row: row,
            plot: plot,
            latitude: latitude,
            longitude: longitude,
            x: record["x"] as? Double,
            y: record["y"] as? Double,
            bearing: record["bearing"] as? Double,
            headstonePhoto: nil,
            landmark: landmark,
            religion: record["religion"] as? String,
            fatherName: record["fatherName"] as? String,
            gender: record["gender"] as? String,
            photos: photos,
            verified: verified,
            stewardName: record["stewardName"] as? String,
            profileMarkdown: record["profileMarkdown"] as? String,
            wallVisibility: record["wallVisibility"] as? String
        )
    }
}

/// Where the last good snapshot lives between launches.
enum CatalogCache {
    private static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("catalog-cache.json")
    }

    static func read() -> RemoteCatalog.Snapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(RemoteCatalog.Snapshot.self, from: data)
    }

    static func write(_ snapshot: RemoteCatalog.Snapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
