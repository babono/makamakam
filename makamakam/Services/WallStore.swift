import Foundation
import CloudKit
import SwiftData
import Observation

/// The wall as the app knows it: what this phone wrote, what CloudKit has, and
/// what the family decided about it.
///
/// Everything is written to the phone first and pushed afterwards, because the
/// place this is used has unreliable reception and a visit that failed to send
/// is still a visit that happened.
@Observable
final class WallStore {
    private(set) var remotePosts: [WallSync.RemotePost] = []
    private(set) var decisions: [String: Memory.Approval] = [:]
    private(set) var isSyncing = false
    private(set) var lastSyncFailed = false
    private(set) var canWrite = false
    /// What iCloud says about this phone, for Settings to report plainly.
    private(set) var account: CKAccountStatus = .couldNotDetermine

    /// Shown once, before the first thing this person ever posts. Not a login —
    /// there is nothing to log into — but people are owed an explanation of
    /// where their words are about to go.
    var hasBeenTold: Bool {
        get { UserDefaults.standard.bool(forKey: "wall.destinationExplained") }
        set { UserDefaults.standard.set(newValue, forKey: "wall.destinationExplained") }
    }

    init() {
        if let cached = WallCache.read() { apply(cached) }
    }

    // MARK: Reading

    @MainActor
    func refresh(pushing context: ModelContext? = nil) async {
        guard WallSync.isAvailable, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        account = await WallSync.accountStatus()
        canWrite = account == .available
        if let context { await push(from: context) }

        do {
            let (posts, decisions) = try await WallSync.fetch()
            remotePosts = posts
            self.decisions = Self.latest(of: decisions)
            WallCache.write(
                WallCache.Snapshot(
                    posts: posts.map {
                        .init(id: $0.id, graveID: $0.graveID, authorName: $0.authorName,
                              relationship: $0.relationship, isVisit: $0.isVisit,
                              leftFlowers: $0.leftFlowers, body: $0.body, postedAt: $0.postedAt)
                    },
                    decisions: decisions.map {
                        .init(postID: $0.postID, approval: $0.approval.rawValue, decidedAt: $0.decidedAt)
                    },
                    fetchedAt: .now
                )
            )
            lastSyncFailed = false
        } catch {
            lastSyncFailed = true
        }
    }

    /// The most recent decision wins, so a steward can change their mind.
    private static func latest(of decisions: [WallSync.RemoteDecision]) -> [String: Memory.Approval] {
        var newest: [String: WallSync.RemoteDecision] = [:]
        for decision in decisions {
            if let existing = newest[decision.postID], existing.decidedAt >= decision.decidedAt { continue }
            newest[decision.postID] = decision
        }
        return newest.mapValues(\.approval)
    }

    @MainActor
    private func apply(_ snapshot: WallCache.Snapshot) {
        remotePosts = snapshot.posts.map {
            WallSync.RemotePost(
                id: $0.id, graveID: $0.graveID, authorName: $0.authorName,
                relationship: $0.relationship, isVisit: $0.isVisit,
                leftFlowers: $0.leftFlowers, body: $0.body, postedAt: $0.postedAt
            )
        }
        decisions = snapshot.decisions.reduce(into: [:]) { result, decision in
            result[decision.postID] = Memory.Approval(rawValue: decision.approval)
        }
    }

    // MARK: Writing

    /// Sends anything this phone has written and CloudKit has not seen.
    @MainActor
    func push(from context: ModelContext) async {
        guard WallSync.isAvailable, canWrite else { return }

        for post in (try? context.fetch(FetchDescriptor<WallPostRecord>())) ?? [] where !post.synced {
            do {
                try await WallSync.send(
                    id: post.id, graveID: post.graveID,
                    authorName: post.authorName, relationship: post.relationship,
                    isVisit: post.visitedInPerson, leftFlowers: post.leftFlowers,
                    body: post.body.isEmpty ? nil : post.body, postedAt: post.postedAt
                )
                post.synced = true
            } catch {
                // Left unsynced on purpose: it goes out on the next refresh, and
                // the post is already safe on this phone.
            }
        }
        try? context.save()
    }

    /// A steward's decision, recorded locally at once and sent when it can be.
    @MainActor
    func decide(
        _ approval: Memory.Approval,
        postID: String,
        graveID: String,
        steward: String,
        context: ModelContext
    ) async {
        decisions[postID] = approval
        Records.setApproval(approval, forEntry: postID, graveID: graveID, context: context)
        guard WallSync.isAvailable, canWrite else { return }
        try? await WallSync.decide(postID: postID, graveID: graveID, approval: approval, by: steward)
    }

    // MARK: Composing the wall

    /// CloudKit posts for one grave, with the family's decisions applied.
    ///
    /// Post-moderation: everything is visible until a `WallDecision` takes it
    /// down, so the default here is approved rather than pending.
    func entries(for graveID: String, includeRemoved: Bool = false) -> [WallEntry] {
        remotePosts
            .filter { $0.graveID == graveID }
            .map { post in
                WallEntry(
                    id: post.id,
                    graveID: post.graveID,
                    authorName: post.authorName,
                    relationship: post.relationship,
                    body: post.body,
                    postedAt: post.postedAt,
                    visitedInPerson: post.isVisit,
                    leftFlowers: post.leftFlowers,
                    approval: decisions[post.id] ?? .approved
                )
            }
            .filter { includeRemoved || $0.approval != .removed }
    }
}
