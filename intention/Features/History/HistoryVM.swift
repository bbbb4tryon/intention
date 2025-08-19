//
//  HistoryVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

enum HistoryError: Error, Equatable {   case categoryNotFound, historyNotLoaded, saveHistoryFailed, moveFailed  }

@MainActor
final class HistoryVM: ObservableObject {
    @Published var categories: [CategoriesModel] = []
    @Published var tileLimitWarning: Bool = false
    @Published var lastUndoableMove: (tile: TileM, from: UUID, to: UUID)? = nil
    @Published var lastError: Error? = nil
    
    private let persistence: Persistence
    private let archiveActor = ArchiveActor()
//    private let userService: UserService
    private let storageKey = "categories data"
    private let tileSoftCap = 200
    
    /// HistoryVM owns IDs
    @AppStorage("generalCategoryID") private var generalCategoryIDString: String = ""
    @AppStorage("archiveCategoryID") private var archiveCategoryIDString: String = ""
    
    var generalCategoryID: UUID {
            get { UUID(uuidString: generalCategoryIDString) ?? { let u = UUID(); generalCategoryIDString = u.uuidString; return u }() }
            set { generalCategoryIDString = newValue.uuidString }
        }
        var archiveCategoryID: UUID {
            get { UUID(uuidString: archiveCategoryIDString) ?? { let u = UUID(); archiveCategoryIDString = u.uuidString; return u }() }
            set { archiveCategoryIDString = newValue.uuidString }
        }
    
    
    // AppStorage wrapper (private, not accessed directly from the view)
    // since `historyVM` is injected into `FocusSessionVM` at startup via `RootView`
    //  the `FocusSessionVM` `func checkSessionCompletion()`'s `addSession(tiles)`
    //  method successfully archives each 2-tile session in and survives app restarts:
    @AppStorage("categoriesData") private var categoryData: Data = Data()   //FIXME: - were for userService - can remove?
    /// `saveHistory` calls keep storage synced, the program will rehydrate using `loadHistory()` on launch only, don't watch `categoryData`
    // Don't use any `onChange`
//    init(persistence: Persistence = PersistenceActor(), userService: UserService) {      //FIXME: - were for userService - can remove?
    init(persistence: Persistence = PersistenceActor()) {
        self.persistence = persistence
//        self.userService = userService
        Task {  await loadHistory() }
    }
    
    private func loadHistory() async {
        do {
            if let loaded: [CategoriesModel] = try await persistence.loadHistory([CategoriesModel].self, from: storageKey) {
                self.categories = loaded
                
                /// Ensure Archive category exists and hydrate it with persisted archived tiles
                let archived = await archiveActor.loadArchivedTiles()
                let archiveID = archiveCategoryID
//                let archiveID = userService.archiveCategoryID   //FIXME: - were for userService - can remove?
                
                if let index = categories.firstIndex(where: { archivedItem in archivedItem.id == archiveID }) {       //FIXME: alternatively, use $0.id = archivedID
                    categories[index].tiles = archived
                } else {
                    /// Add archive category if not found
                    let newArchive = CategoriesModel(id: archiveID, persistedInput: "Archive", tiles: archived)
                    categories.append(newArchive)
                }
            }
        } catch {
            debugPrint("[History(persistence's).loadHistory] error: ", error )
            await MainActor.run { self.lastError = error }
        }
    }
    
    
    // MARK: - Sets automatic "General" category aka "bootstrapping"
    func ensureGeneralCategory(named name: String = "General") {
        let generalID = generalCategoryID
        if !categories.contains(where: { generalCategoryItem in generalCategoryItem.id == generalID }) {
            let new = CategoriesModel(id: generalID, persistedInput: name)
            categories.insert(new, at: 0)
            debugPrint("HistoryVM.ensureGeneralCategory: created 'Misellaneous'")
            saveHistory()
        }
    }
    
    // MARK: - Sets automatic Archive category aka "bootstrapping"
    func ensureArchiveCategory(named name: String = "Archive") {
        let archiveID = archiveCategoryID
        if !categories.contains(where: { archiveCategoryItem in archiveCategoryItem.id == archiveID }) {
            let new = CategoriesModel(id: archiveID, persistedInput: name)
            categories.insert(new, at: 0)
            debugPrint("HistoryVM.ensureArchiveCategory: created 'Archive'")
            saveHistory()
        }
    }
    
    
    func limitCheck() {
        let total = categories.reduce(0) { $0 + $1.tiles.count }        //FIXME: alternatively, use reduce(0) { $0 + $1.tiles.count }
        tileLimitWarning = total > tileSoftCap
        guard tileLimitWarning else { return }
        
        Task {
            do {
                try await archiveActor.offloadOldTiles(from: categories, maxTiles: tileSoftCap)
            } catch {
                debugPrint("[HistoryVM.limitCheck] offload error: ", error)
                await MainActor.run { self.lastError = HistoryError.saveHistoryFailed   }
            }
        }
    }
    
    // MARK: - Non-throwing convenience (fire-and-forget)
    /// Non-throwing wrapper, background with a UI signal; catch internally, debugPrints, sets VM lasterror; saveHistory() calls saveHistoryThrowing() inside a Task
    /// Save the current categories array -> wrapper of PersistenceActor.saveHistory
    func saveHistory() {
        Task {
            do { try await saveHistoryThrowing() }
            catch {
                debugPrint("[HistoryVM.saveHistory] failed:", error)
                await MainActor.run { self.lastError = HistoryError.saveHistoryFailed }
            }
        }
    }
    
    // MARK: - Add a tile to a specific category (non-throwing convenience)
    func addToHistory(_ newTile: TileM, to categoryID: UUID) {
        guard let index = categories.firstIndex(where: {  categoryItem in       // $0.id == categoryID
            categoryItem.id == categoryID
        }) else {
            debugPrint("HistoryVM.addToHistory] Category ID not found. Tile not added.")
            self.lastError = HistoryError.categoryNotFound
            return
        }
        /// "capped FIFO" newest-first for UI display
        categories[index].tiles.insert(newTile, at: 0)
        
        /// Once all tiles equal 200, offload oldest
        let totalTileCount = categories.reduce(0) { $0 + $1.tiles.count }
        if totalTileCount > tileSoftCap {
            limitCheck()
        }
        
        // saveHistory() is inside addToHistory() to persist automatically
        saveHistory()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    
    // MARK: - Add a new category
    func addCategory(persistedInput: String){
        let newCategory = CategoriesModel(persistedInput: persistedInput)
        categories.append(newCategory)
        saveHistory()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: valid target to call to move tiles within categories
    func moveTile(_ tile: TileM, from fromID: UUID, to toID: UUID) {
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
            do {
                try await moveTileThrowing(move.tile, from: move.to, to: move.from)
                await MainActor.run { lastUndoableMove = nil    }
            } catch {
                debugPrint("[HistoryVM.undoLastMove] error: ", error)
                await MainActor.run { self.lastError = lastError   }
            }
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
    
    // MARK: Helpers + Throwing Core
    
    ///Throwing core (async throws): use when the caller wants to decide how to handle the error
    /// SaveHistory() wraps Task and sets lastError internally - Throwing variant provided
    func saveHistoryThrowing() async throws {
        try await persistence.saveHistory(categories, to: storageKey)
    }
    
    func addToHistoryThrowing(_ tile: TileM, to categoryID: UUID) async throws {
        guard let index = categories.firstIndex(where: {  categoryItem in
            categoryItem.id == categoryID
        }) else {
            debugPrint("HistoryVM.addToHistory] Category ID not found. Tile not added.")
            throw HistoryError.categoryNotFound
        }
        categories[index].tiles.insert(tile, at: 0)
        try await saveHistoryThrowing()
    }
    
    func moveTileThrowing(_ tile: TileM, from fromID: UUID, to toID: UUID) async throws {
        guard
            let fromIndex = categories.firstIndex(where: { $0.id == fromID }),
            let toIndex = categories.firstIndex(where: { $0.id == toID }),
            let tileIndex = categories[fromIndex].tiles.firstIndex(of: tile)
        else {
            debugPrint("Move failed: could not locate source or destination HistoryVM.moveTile")
            return
        }
        let moving = categories[fromIndex].tiles.remove(at: tileIndex)
        categories[toIndex].tiles.insert(moving, at: 0)
        try await saveHistoryThrowing()
    }
}
