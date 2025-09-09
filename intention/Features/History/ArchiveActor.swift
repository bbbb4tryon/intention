//
//  ArchiveActor.swift
//  intention
//
//  Created by Benjamin Tryon on 7/26/25.
//

import Foundation
// dedicated actor to handle offloading old tiles
// receives a [CategoriesModel], trims tiles beyond the 200 tile cap and persist

/// Purpose: points to a tile where it lives without copying text or timeStamp. Different than TileM (the full model) and different than TileOrganizerVM (a ViewModel for UI organizing)
/// Identity used for offloading between actors
struct TileRef: Hashable, Codable, Sendable {
    let categoryID: UUID
    let tileID: UUID
}

actor ArchiveActor {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let archiveKey = "archivedTiles"

    struct OffloadResult: Sendable, Codable {
        let archived: [TileM]           /// full tiles archived oldest first
        let refs: [TileRef]             /// exact locations the tiles came from
    }
    
    /// Offload tiles to archive storage, oldest-first, **excluding** Archive category
    /// - Parameters:
    ///     - categories: to consider
    ///     - maxLiveTiles: cap for *live* tiles (General + user categories)
    /// - Returns: OffloadResult with exact refs & tiles archived; Empty if no overflow
    func offloadOldTiles(from categories: [CategoriesModel], maxTiles: Int) async throws {
        let all = categories.flatMap(\.tiles).sorted { $0.timeStamp < $1.timeStamp } // oldest first
        let overflowCount = max(0, all.count - maxTiles)
        guard overflowCount > 0 else { return }

        let toArchive = Array(all.prefix(overflowCount))  // take the oldest overflow
        let data = try encoder.encode(toArchive)
        UserDefaults.standard.set(data, forKey: archiveKey)
        debugPrint("ArchiveActor: Archived \(toArchive.count) tiles.")
    }
    
    
    // Load archived tiles for testing or restoration.
    func loadArchivedTiles() async -> [TileM] {
        guard let data = UserDefaults.standard.data(forKey: archiveKey) else { return [] }
        do {
            return try decoder.decode([TileM].self, from: data)
        } catch {
            debugPrint("ArchiveActor: Failed to decode archived tiles - \(error)")
            return []
        }
    }
    // Clear archive for testing/reset
    func clearArchive() {
        UserDefaults.standard.removeObject(forKey: archiveKey)
    }
}
