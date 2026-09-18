import Foundation
import SwiftData

/// Reads and writes for the local store. Kept in one place so views stay about
/// what is on screen.
enum Records {
    // MARK: Saved graves

    static func isSaved(_ graveID: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<SavedGrave>(predicate: #Predicate { $0.graveID == graveID })
        return ((try? context.fetch(descriptor)) ?? []).isEmpty == false
    }

    /// Returns true when the grave is now kept, false when it has been let go —
    /// the caller needs to know which, because letting go has to reach iCloud.
    @discardableResult
    static func toggleSaved(_ graveID: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<SavedGrave>(predicate: #Predicate { $0.graveID == graveID })
        let existing = (try? context.fetch(descriptor)) ?? []
        let nowSaved = existing.isEmpty
        if nowSaved {
            context.insert(SavedGrave(graveID: graveID))
        } else {
            existing.forEach(context.delete)   // deduped in code, not with @Attribute(.unique)
        }
        try? context.save()
        return nowSaved
    }

    // MARK: The wall

    static func posts(for graveID: String, context: ModelContext) -> [WallPostRecord] {
        var descriptor = FetchDescriptor<WallPostRecord>(predicate: #Predicate { $0.graveID == graveID })
        descriptor.sortBy = [SortDescriptor(\.postedAt, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Writes a post. `visitedInPerson` comes from the app's own reading of
    /// where the phone is, never from anything the writer could set.
    static func addPost(
        graveID: String,
        authorName: String,
        relationship: String,
        body: String,
        visitedInPerson: Bool,
        leftFlowers: Bool,
        context: ModelContext
    ) {
        context.insert(
            WallPostRecord(
                graveID: graveID,
                authorName: authorName,
                relationship: relationship,
                body: body,
                visitedInPerson: visitedInPerson,
                // Flowers are a thing you scatter, so they only exist on a visit.
                leftFlowers: visitedInPerson && leftFlowers
            )
        )
        try? context.save()
    }

    // MARK: Stewardship

    static func steward(for graveID: String, store: GraveStore, context: ModelContext) -> String? {
        let descriptor = FetchDescriptor<StewardClaim>(predicate: #Predicate { $0.graveID == graveID })
        if let claim = ((try? context.fetch(descriptor)) ?? []).first {
            return claim.stewardName
        }
        return store.grave(id: graveID)?.stewardName
    }

    /// The first immediate-family claimant becomes steward.
    static func claimStewardship(graveID: String, name: String, context: ModelContext) {
        let descriptor = FetchDescriptor<StewardClaim>(predicate: #Predicate { $0.graveID == graveID })
        guard ((try? context.fetch(descriptor)) ?? []).isEmpty else { return }
        context.insert(StewardClaim(graveID: graveID, stewardName: name))
        try? context.save()
    }

    static func isSteward(_ identity: Identity, graveID: String, store: GraveStore, context: ModelContext) -> Bool {
        guard identity.isNamed else { return false }
        return steward(for: graveID, store: store, context: context) == identity.name
    }

}

extension Records {
    /// Everything that has happened at this grave, oldest first.
    ///
    /// Post-moderation: an entry is on the wall the moment it is written, and
    /// leaves only if the steward takes it down.
    static func wall(
        for grave: Grave,
        store: GraveStore,
        context: ModelContext,
        includeRemoved: Bool = false
    ) -> [WallEntry] {
        var entries: [WallEntry] = []

        for visit in store.visits(for: grave.id) {
            entries.append(
                WallEntry(
                    id: visit.id, graveID: grave.id,
                    authorName: visit.visitorName, relationship: "",
                    body: nil, postedAt: visit.date,
                    visitedInPerson: true, leftFlowers: visit.leftFlower,
                    approval: .approved
                )
            )
        }

        for memory in store.memories(for: grave.id) {
            entries.append(
                WallEntry(
                    id: memory.id, graveID: grave.id,
                    authorName: memory.authorName, relationship: memory.relationship,
                    body: memory.body, postedAt: memory.writtenAt,
                    visitedInPerson: false, leftFlowers: false,
                    approval: .approved
                )
            )
        }

        for post in posts(for: grave.id, context: context)
        where includeRemoved || post.approval != .removed {
            entries.append(
                WallEntry(
                    id: post.id, graveID: grave.id,
                    authorName: post.authorName, relationship: post.relationship,
                    body: post.body.isEmpty ? nil : post.body,
                    postedAt: post.postedAt,
                    visitedInPerson: post.visitedInPerson, leftFlowers: post.leftFlowers,
                    approval: post.approval
                )
            )
        }

        // The wall begins on the day of the death; nothing can precede it.
        if let died = grave.deathDateValue {
            entries = entries.filter { $0.postedAt >= died }
        }
        return entries.sorted { $0.postedAt < $1.postedAt }
    }

    static func setApproval(
        _ approval: Memory.Approval,
        forEntry id: String,
        graveID: String,
        context: ModelContext
    ) {
        guard let post = posts(for: graveID, context: context).first(where: { $0.id == id }) else { return }
        post.approval = approval
        try? context.save()
    }

    // MARK: Who may read the wall

    static func wallVisibility(for grave: Grave, context: ModelContext) -> WallVisibility {
        let id = grave.id
        let descriptor = FetchDescriptor<WallSetting>(predicate: #Predicate { $0.graveID == id })
        if let setting = ((try? context.fetch(descriptor)) ?? []).first {
            return WallVisibility(rawValue: setting.visibilityRaw) ?? grave.wall
        }
        return grave.wall
    }

    static func setWallVisibility(
        _ visibility: WallVisibility,
        for graveID: String,
        context: ModelContext
    ) {
        let descriptor = FetchDescriptor<WallSetting>(predicate: #Predicate { $0.graveID == graveID })
        if let existing = ((try? context.fetch(descriptor)) ?? []).first {
            existing.visibilityRaw = visibility.rawValue
        } else {
            context.insert(WallSetting(graveID: graveID, visibilityRaw: visibility.rawValue))
        }
        try? context.save()
    }
}
