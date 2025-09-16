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

/// Purpose: archives tiles into persistent list
/// dedicated, thread-safe manager - handles offloading into archive from "live" categories dedicated, thread-safe manager for archiving tiles. It handles offloading old tiles from live categories to a persistent archive, ensuring the total count of tiles remains below a specified limit.
/// The **only store of Archive tiles** (authoritative for Archive contents

actor ArchiveActor {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let archiveKey = "archivedTiles"
//
//    struct OffloadResult: Sendable, Codable {
//        let archived: [TileM]           /// full tiles archived first, and in the bottom most location of the archive
//        let refs: [TileRef]             /// exact locations the tiles came from
//    }
//    
//    /// Offload tiles to archive storage, top-first, **excluding** Archive category
//    /// - Parameters:
//    ///     - categories: to consider
//    ///     - maxTiles: cap for *live* tiles (General + user categories)
//    /// - Returns: OffloadResult with exact refs & tiles archived; Empty if no overflow
//    func offloadOldTiles(from categories: [CategoriesModel], maxTiles: Int) async throws {
//        // 1) Flatten only non-Archive categories (HistoryVM will pass those; this is defensive)
//        let live = categories
//        // 2) oldest/bottom first across live times
//        let all = live.flatMap(\.tiles).sorted { $0.timeStamp < $1.timeStamp }
//        let overflowCount = max(0, all.count - maxTiles)
//        guard overflowCount > 0 else { return }
//        
//        // the oldest overflow that must be offloaded
//        let toArchive = Array(all.prefix(overflowCount))  // take the oldest overflow
//
//        // 3) Append to existing archive (keep newest at top in storage)
//        let existing = await loadArchivedTiles()
//        var combined = toArchive.reversed() + existing     // put “newly archived” on top
//        if combined.count > maxTiles {
//            combined.removeLast(combined.count - maxTiles) // drop oldest from bottom
//        }
//
//        let data = try encoder.encode(combined)
//        UserDefaults.standard.set(data, forKey: archiveKey)
//        #if DEBUG
//        debugPrint("ArchiveActor: Archived \(toArchive.count) tiles. Archive total: \(combined.count)")
//        #endif
//    }
    
    
    // Write/load archived tiles for testing or restoration.
    func loadArchivedTiles() async -> [TileM] {
        guard let data = UserDefaults.standard.data(forKey: archiveKey) else { return [] }
        do { return try decoder.decode([TileM].self, from: data) }
        catch { debugPrint("ArchiveActor: decode archived tiles failed:", error); return [] }
    }
    
    // Update on every Archive mutation
    func saveArchivedTiles(_ tiles: [TileM]) async {
        if let data = try? encoder.encode(tiles) {
            UserDefaults.standard.set(data, forKey: archiveKey)
        }
    }
    
    // Clear archive for testing/reset
    func clearArchive() { UserDefaults.standard.removeObject(forKey: archiveKey) }
}
