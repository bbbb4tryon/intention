//
//  HistoryVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

enum HistoryError: Error, Equatable {
    case categoryNotFound
    case historyNotLoaded
    case saveHistoryFailed
}

@MainActor
final class HistoryVM: ObservableObject {
    @Published var categories: [CategoriesModel] = []
    @Published var tileLimitWarning: Bool = false
    @Published var lastUndoableMove: (tile: TileM, from: UUID, to: UUID)? = nil
    @Published var lastError: Error? = nil
    
    private let persistence: Persistence
    private let archiveActor = ArchiveActor()
    private let storageKey = "categories data"
    private let tileSoftCap = 200
    
    // AppStorage wrapper (private, not accessed directly from the view)
    // since `historyVM` is injected into `FocusSessionVM` at startup via `RootView`
    //  the `FocusSessionVM` `func checkSessionCompletion()`'s `addSession(tiles)`
    //  method successfully archives each 2-tile session in and survives app restarts:
    @AppStorage("categoriesData") private var categoryData: Data = Data()
    
    /// `saveHistory` calls keep storage synced, the program will rehydrate using `loadHistory()` on launch only, don't watch `categoryData`
    // Don't use any `onChange`
    init(persistence: Persistence = PersistenceActor()) {
        self.persistence = persistence
        Task {  await loadHistory() }
    }
    
    private func loadHistory() async {
        do {
            if let loaded: [CategoriesModel] = try await persistence.loadHistory([CategoriesModel].self, from: storageKey) {
                self.categories = loaded
            }
        } catch {
            debugPrint(("[History.loadHistory persistence.loadHistory]", error ))
            await MainActor.run { self.lastError = error }
        }
    }
    
    func limitCheck() {
        let total = categories.reduce(0) { $0 + $1.tiles.count }
        if total > tileSoftCap {
            tileLimitWarning = true
            Task {  try await archiveActor.offloadOldTiles(from: categories, maxTiles: tileSoftCap) }
        } else {
            tileLimitWarning = false
        }
    }
    
    // Save the current categories array -> wrapper of PersistenceActor.saveHistory
    func saveHistory() {
        let current = categories
        Task {
            do {
                try await persistence.saveHistory(current, to: storageKey)
            } catch {
                debugPrint("[HistoryVM.saveHistory] failed:", error)
                await MainActor.run { self.lastError = HistoryError.saveHistoryFailed }
            }
        }
    }
    
    // MARK: - Add a tile to a specific category
    func addToHistory(_ newTile: TileM, to categoryID: UUID){
        guard let index = categories.firstIndex(where: {  categoryItem in
            categoryItem.id == categoryID
        }) else {
            debugPrint("HistoryVM.addToHistory] Category ID not found. Tile not added.")
            self.lastError = HistoryError.categoryNotFound
            return
        }
        
        // "capped FIFO" newest-first for UI display
        categories[index].tiles.insert(newTile, at: 0)
        
        // Once all tiles equal 200, then offload oldest
        let totalTileCount = categories.reduce(0) { $0 + $1.tiles.count }
        
        if totalTileCount > tileSoftCap {
            Task {
                do {
                    try await archiveActor.offloadOldTiles(from: categories, maxTiles: tileSoftCap)
                } catch {
                    debugPrint("[HistoryVM.addToHistory tile cap] error:", error )
                    await MainActor.run { self.lastError = HistoryError.saveHistoryFailed }
                }
            }
        }
        
        // saveHistory() is inside addToHistory() to persist automatically
        saveHistory()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    //https://www.avanderlee.com/swiftui/viewbuilder/
    // MARK: Add a new category
    func addCategory(persistedInput: String){
        let newCategory = CategoriesModel(persistedInput: persistedInput)
        categories.append(newCategory)
        saveHistory()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: sets default category
    func ensureDefaultCategory(named name: String = "Miscellaneous", userService: UserService) {
        let defaultID = userService.defaultCategoryID
        
        if !categories.contains(where: { defaultCategoryItem in
            defaultCategoryItem.id == defaultID
        }) {
            let new = CategoriesModel(id: defaultID, persistedInput: name)
            categories.insert(new, at: 0)
            debugPrint("HistoryVM.ensureDefaultCategory error")
            saveHistory()
        }
    }
    
    // MARK: sets archive category
    func ensureArchiveCategory(named name: String = "Archive", userService: UserService) {
        let defaultID = userService.defaultCategoryID
        
        if !categories.contains(where: { defaultCategoryItem in
            defaultCategoryItem.id == defaultID
        }) {
            let new = CategoriesModel(id: defaultID, persistedInput: name)
            categories.insert(new, at: 0)
            debugPrint("HistoryVM.ensureArchiveCategory error")
            saveHistory()
        }
    }
    
    // MARK: valid target to call to move tiles within categories
    func moveTile(_ tile: TileM, from fromID: UUID, to toID: UUID) async {
        guard
            let fromIndex = categories.firstIndex(where: { $0.id == fromID }),
            let toIndex = categories.firstIndex(where: { $0.id == toID }),
            let tileIndex = categories[fromIndex].tiles.firstIndex(of: tile)
        else {
            debugPrint("Move failed: could not locate source or destination HistoryVM.moveTile")
            return
        }
        
        let movingTile = categories[fromIndex].tiles.remove(at: tileIndex)
        categories[toIndex].tiles.insert(movingTile, at: 0)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        saveHistory()
        
        lastUndoableMove = (movingTile, fromID, toID)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Task { @MainActor in
                self.lastUndoableMove = nil         // clear undo after 3s if not acted upon (via toast)
            }
        }
    }
    
    func undoLastMove() {
        guard let move = lastUndoableMove else { return }
        Task {
            await moveTile(move.tile, from: move.to, to: move.from)
            lastUndoableMove = nil
        }
    }
    
    func updateTiles(in categoryID: UUID, to newTiles: [TileM]) {
        if let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].tiles = newTiles
        }
    }
    
    // MARK: reset all categories
    func clearHistory() {
        categories = []     // clears model first
        saveHistory()       // persists a cleared list
        
        Task {  await persistence.clear(storageKey) }   // clear storage safely: see PersistenceActor
    }
}
