//
//  ArchiveActor.swift
//  intention
//
//  Created by Benjamin Tryon on 7/26/25.
//

import Foundation
// dedicated actor to handle offloading old tiles
// recevies a [CategoriesModel], trims tiles beyond the 200 tile cap and persist

actor ArchiveActor {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let archiveKey = "archivedTiles"
    
    // Moves tiles exceeding `maxTiles` into archive storage.
    func offloadOldTiles(from categories: [CategoriesModel], maxTiles: Int) throws {
        var allTiles: [(tile: TileM, categoryID: UUID)] = []
        
        // Flatten all tiles with their category ID
        for category in categories {
            for tile in category.tiles {
                allTiles.append((tile, category.id))
            }
        }
        // Sort by insertion order (oldest last in array)
        // Assuming tiles are newest-first in HistoryVM
        let overflow = allTiles.dropFirst(maxTiles)
        
        guard !overflow.isEmpty else { return }
        
        // Persist overflow tiles to archive
        do {
            let data = try encoder.encode(overflow.map { $0.tile })
            UserDefaults.standard.set(data, forKey: archiveKey)
            debugPrint("ArchiveActor: Archived \(overflow.count) tiles.")
        } catch {
            debugPrint("ArchiveActor: Failed to archive tiles - \(error)")
        }
    }
    
    // Load archived tiles for testing or restoration.
    func loadArchivedTiles() -> [TileM] {
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
