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
    /// Every cemetery the app knows the inside of. Usually one; there is no
    /// reason it should be.
    private(set) var cemeteries: [Site]
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

    /// The bundled cemetery. Kept because a good deal of the app is written for
    /// "the cemetery you are looking at" and only needs one when there is one.
    var site: Site { cemeteries.first ?? Self.load().site }

    init() {
        let file = Self.load()
        cemeteries = [file.site]
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
            guard !snapshot.cemeteries.isEmpty, !snapshot.graves.isEmpty else { return }
            guard isImprovement(snapshot) else { return }
            CatalogCache.write(snapshot)
            apply(snapshot)
            lastSyncFailed = false
        } catch {
            lastSyncFailed = true
        }
    }

    /// Whether a fetch is worth keeping.
    ///
    /// A CloudKit query can come back short without coming back empty — most
    /// reliably in the minutes after a schema import, while the indexes are
    /// rebuilt. Such a reply looks like a perfectly good survey with a cemetery
    /// or a set of photographs quietly missing from it, and because every
    /// refresh overwrites the cache, one badly timed fetch leaves a burial
    /// ground unreachable until the next one happens to land.
    ///
    /// So a snapshot may add and it may correct, but it may not shrink the
    /// catalogue. Records really do get deleted, and Settings has "forget the
    /// downloaded survey" for exactly that — a deliberate act, not a side
    /// effect of bad timing.
    private func isImprovement(_ snapshot: RemoteCatalog.Snapshot) -> Bool {
        guard lastSynced != nil else { return true }
        if snapshot.cemeteries.count < cemeteries.count { return false }
        if snapshot.graves.count < graves.count { return false }
        let hadPhotos = photoCount(cemeteries, graves)
        return hadPhotos == 0 || photoCount(snapshot.cemeteries, snapshot.graves) > 0
    }

    private func photoCount(_ sites: [Site], _ graves: [Grave]) -> Int {
        sites.reduce(0) { $0 + ($1.photos?.count ?? 0) }
            + graves.reduce(0) { $0 + ($1.photos?.count ?? 0) }
    }

    @MainActor
    private func apply(_ snapshot: RemoteCatalog.Snapshot) {
        cemeteries = snapshot.cemeteries
        graves = snapshot.graves
        lastSynced = snapshot.fetchedAt
    }

    /// Drops the downloaded snapshot and returns to the bundled survey.
    @MainActor
    func forgetSnapshot() {
        CatalogCache.clear()
        let file = Self.load()
        cemeteries = [file.site]
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

    /// The bundled photographs of a cemetery plus anything the field sheet
    /// captured on this device.
    func photos(for site: Site) -> [GravePhoto] {
        (site.photos ?? []) + SitePhotoStore.captured(for: site.id)
    }

    /// The graves inside one cemetery. A record with no cemetery named belongs
    /// to the bundled one, which is how every seeded grave reads.
    func graves(in site: Site) -> [Grave] {
        graves.filter { ($0.cemeteryId ?? self.site.id) == site.id }
    }

    /// Which cemetery a grave lies in.
    func site(of grave: Grave) -> Site {
        cemeteries.first { $0.id == (grave.cemeteryId ?? site.id) } ?? site
    }

    func cemetery(id: String) -> Site? {
        cemeteries.first { $0.id == id }
    }

    func grave(id: String) -> Grave? {
        graves.first { $0.id == id }
    }

    /// Name search across every surveyed cemetery.
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
