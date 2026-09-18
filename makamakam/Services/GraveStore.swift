import Foundation
import CoreLocation
import Observation

/// The survey the app is working from.
///
/// Three layers, in order of preference: the bundled `graves.json`, then the
/// last snapshot CloudKit gave us, then a fresh fetch. The bundle is the floor
/// and never goes away — rural reception is unreliable and everything has to
/// work with the radio off (PRD §13) — so CloudKit can only ever improve what is
/// already there, never take it away.
@Observable
final class GraveStore {
    private(set) var site: Site
    private(set) var graves: [Grave]
    private(set) var seedMemories: [Memory]
    private(set) var seedVisits: [Visit]

    /// When the records on screen were last refreshed from CloudKit. Nil means
    /// the app is running on the bundle alone, which is a perfectly good state.
    private(set) var lastSynced: Date?
    private(set) var isSyncing = false
    /// True when the last attempt failed. Shown only where someone went looking
    /// for it — never as an alert over a grave.
    private(set) var lastSyncFailed = false

    init() {
        let file = Self.load()
        site = file.site
        graves = file.graves
        seedMemories = file.memories.map {
            Memory(id: $0.id, graveID: $0.graveID, authorName: $0.authorName,
                   relationship: $0.relationship, body: $0.body,
                   writtenAt: $0.writtenAt, approval: .approved)
        }
        seedVisits = file.visits.map {
            Visit(id: $0.id, graveID: $0.graveID, visitorName: $0.visitorName,
                  date: $0.date, leftFlower: $0.leftFlower)
        }

        // A snapshot from a previous launch is newer than the bundle by
        // definition, and is available before any network call returns.
        if let cached = CatalogCache.read() {
            apply(cached)
        }
    }

    /// Asks CloudKit for the current survey. Silent on failure by design: the
    /// person is standing in a cemetery looking for a grave, and a sync error is
    /// not their problem.
    /// Whether this build can sync at all. False in an unsigned simulator run,
    /// and shown as such in Settings rather than as a failure.
    var canSync: Bool { RemoteCatalog.isAvailable }

    @MainActor
    func refresh() async {
        guard canSync, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let snapshot = try await RemoteCatalog.fetch()
            guard !snapshot.graves.isEmpty else { return }
            CatalogCache.write(snapshot)
            apply(snapshot)
            lastSyncFailed = false
        } catch {
            lastSyncFailed = true
        }
    }

    @MainActor
    private func apply(_ snapshot: RemoteCatalog.Snapshot) {
        site = snapshot.site
        graves = snapshot.graves
        lastSynced = snapshot.fetchedAt
    }

    /// Drops the downloaded snapshot and returns to the bundled survey.
    @MainActor
    func forgetSnapshot() {
        CatalogCache.clear()
        let file = Self.load()
        site = file.site
        graves = file.graves
        lastSynced = nil
        lastSyncFailed = false
    }

    private static func load() -> SeedFile {
        guard let url = Bundle.main.url(forResource: "graves", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("graves.json is missing from the bundle.")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(SeedFile.self, from: data)
        } catch {
            fatalError("graves.json could not be read: \(error)")
        }
    }

    /// The bundled photographs of the cemetery plus anything the field sheet
    /// captured on this device.
    var sitePhotos: [GravePhoto] {
        (site.photos ?? []) + SitePhotoStore.captured
    }

    func grave(id: String) -> Grave? {
        graves.first { $0.id == id }
    }

    /// Name search, plus the plot code for the caretaker's own use. Typing a
    /// name goes straight to the grave (PRD §11).
    func search(_ term: String) -> [Grave] {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        return graves
            .filter {
                $0.name.lowercased().contains(query)
                || $0.shortPlotLabel.lowercased().contains(query)
                || ($0.deathDate ?? "").contains(query)
            }
            .sorted { $0.name < $1.name }
    }

    func memories(for graveID: String) -> [Memory] {
        seedMemories.filter { $0.graveID == graveID }
    }

    func visits(for graveID: String) -> [Visit] {
        seedVisits.filter { $0.graveID == graveID }
    }
}
