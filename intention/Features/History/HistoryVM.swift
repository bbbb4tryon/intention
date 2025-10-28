//
//  HistoryVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

enum HistoryError: Error, Equatable, LocalizedError {
    case categoryNotFound, historyNotLoaded, saveHistoryFailed, moveFailed

    var errorDescription: String? {
        switch self {
        case .categoryNotFound: return "Category not found."
        case .historyNotLoaded: return "History not loaded."
        case .saveHistoryFailed: return "Could not save history."
        case .moveFailed: return "Tile move failed."
        }
    }
}

/// VM decides *when*, persistence/actors decide *how*.
/// Single source of truth for General/Archive IDs and category ordering.
@MainActor
final class HistoryVM: ObservableObject {
    // MARK: - Published UI state
        @Published var categories: [CategoriesModel] = []
        @Published var categoryValidationMessages: [UUID: [String]] = [:]
        @Published var tileLimitWarning: Bool = false
        @Published var lastUndoableMove: (tile: TileM, from: UUID, to: UUID)?
        @Published var lastError: Error?
    
    // MARK: - Dependencies
    private let persistence: any Persistence
    private let archiveActor = ArchiveActor()

    // MARK: - Storage keys / caps / debounce
    private let storageKey = "categoriesData"
    private let tileSoftCap = 200                      // Archive cap
    private var pendingSnapshot: [CategoriesModel]?
    private var debouncedSaveTask: Task<Void, Never>?
    private var lastSavedSignature: Int = 0
    private let saveDebouncedDelayNanos: UInt64 = 300_000_000 // 300 ms
    
    // MARK: - Canonical IDs (persisted)
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
    
    // MARK: - Init
    init(persistence: any Persistence) {
        self.persistence = persistence
        Task { await loadHistory() }
    }

    // MARK: - Load / Bootstrap / Reconcile
       private func loadHistory() async {
           do {
               // 1) Load categories from disk (without Archive tiles; those hydrate from ArchiveActor)
               if let loaded: [CategoriesModel] = try await persistence.readIfExists([CategoriesModel].self, from: storageKey) {
                   categories = loaded
               } else {
                   categories = []
               }

               // 2) Reconcile built-in IDs by name, if present
               if let g = categories.first(where: { $0.persistedInput == "General" }) { generalCategoryID = g.id }
               if let a = categories.first(where: { $0.persistedInput == "Archive" }) { archiveCategoryID = a.id }

               // 3) Ensure both built-ins exist using canonical IDs
               if !categories.contains(where: { $0.id == generalCategoryID }) {
                   categories.insert(CategoriesModel(id: generalCategoryID, persistedInput: "General"), at: 0)
               }
               if !categories.contains(where: { $0.id == archiveCategoryID }) {
                   categories.append(CategoriesModel(id: archiveCategoryID, persistedInput: "Archive"))
               }

               // 4) Hydrate Archive tiles from ArchiveActor and enforce cap (now that the archive ID is canonical)
               let archived = await archiveActor.loadArchivedTiles()
               if let aIdx = categories.firstIndex(where: { $0.id == archiveCategoryID }) {
                   categories[aIdx].tiles = archived
                   applyCaps(afterInsertingIn: aIdx) // trims if > 200 and mirrors back to actor
               }

               // 5) /Persist if anything changed during steps 2–4
               // keeps data in order
               normalizeCategoryOrder()
               // save the sanitized (Archive-empty) snapshot
               saveHistory()

           } catch {
               debugPrint("[HistoryVM.loadHistory] error:", error)
               lastError = error
           }
       }

       /// Reconcile built-ins again on demand; then persist.
       func reconcileAndEnsureBuiltIns() {
           // 1) If categories already contain built-ins, prefer those IDs and write them back to AppStorage.
           if let g = categories.first(where: { $0.persistedInput == "General" }) { generalCategoryID = g.id }
           if let a = categories.first(where: { $0.persistedInput == "Archive" }) { archiveCategoryID = a.id }
           
           // 2) Ensure both exist using the canonical IDs (lazily created if empty).
           if !categories.contains(where: { $0.id == generalCategoryID }) {
               categories.insert(CategoriesModel(id: generalCategoryID, persistedInput: "General"), at: 0)
           }
           if !categories.contains(where: { $0.id == archiveCategoryID }) {
               categories.append(CategoriesModel(id: archiveCategoryID, persistedInput: "Archive"))
           }
           
           // the debounced/immediate server
           normalizeCategoryOrder()
           saveHistory()
       }
    
    // MARK: - Ordering (Canonical - General -> A-Z users, cats -> Archive)

    /// Rebuilds array as: General → (user categories, A–Z by name) → Archive
    /// Call after *every* mutation that could affect order.
    fileprivate func normalizeCategoryOrder() {
        // 1) Pull out General + Archive
        guard
            let gIdx = categories.firstIndex(where: { $0.id == generalCategoryID }),
            let aIdx = categories.firstIndex(where: { $0.id == archiveCategoryID })
        else { return }

        let general = categories[gIdx]
        let archive = categories[aIdx]
        
        // 2) Everything else (user categories) in alphabetical
        let users = categories
            .filter { $0.id != generalCategoryID && $0.id != archiveCategoryID }
            .sorted { $0.persistedInput.localizedCaseInsensitiveCompare($1.persistedInput) == .orderedAscending }
        // 3) Rebuild: General first → users → Archive last
        categories = [general] + users + [archive]
    }
    
    // MARK: - Sanitization & Persistence
    // sanitizedForSave() and performSaveIfChanged - Persist categories without the Archive tiles. Hydrate Archive tiles on load from ArchiveActor
    private func sanitizedForSave(_ cats: [CategoriesModel]) -> [CategoriesModel] {
        cats.map { category in
            var copy = category
            if category.id == archiveCategoryID { copy.tiles = [] }     // keep Archive empty in categoriesData - Archive tiles live in ArchiveActor
            return copy
        }
    }
    
    private func saveSignature(for categories: [CategoriesModel]) -> Int {
        var acc = categories.count
        for cat in categories {
            acc = acc &* 31 &+ cat.id.hashValue &+ cat.tiles.count  //// Mixes ID + tile count
        }
        return acc
    }
    
    // Writes only if content changed since last success - if `snapshot` is nil, uses live `categories`
    private func performSaveIfChanged(_ snapshot: [CategoriesModel]? = nil) async {
        let raw = snapshot ?? categories
        let toWrite = sanitizedForSave(raw)
        let signature = saveSignature(for: toWrite)               // compare sanitized - not raw
        guard signature != lastSavedSignature else { return }
        do {
            try await persistence.write(toWrite, to: storageKey)
            lastSavedSignature = signature
        } catch {
            debugPrint("[HistoryVM.performSaveIfChanged] error: ", error)
            await MainActor.run { self.lastError = HistoryError.saveHistoryFailed }
        }
    }
    
    /// Public save entrypoint.
       func saveHistory(immediate: Bool = false) {
           if immediate {
               let snapshot = categories
               pendingSnapshot = nil
               debouncedSaveTask?.cancel()
               debouncedSaveTask = nil
               Task { await performSaveIfChanged(snapshot) }
               return
           }
           scheduleDebouncedSave()
       }


    private func scheduleDebouncedSave() {
        let snapshot = categories       // Capture now; UI may keep mutating
        pendingSnapshot = snapshot

        debouncedSaveTask?.cancel()
        debouncedSaveTask = Task { [weak self, snapshot ] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: saveDebouncedDelayNanos)
            await self.performSaveIfChanged(snapshot)
            await MainActor.run { self.pendingSnapshot = nil }
        }
    }

    // Call on scenePhase changes, or when leaving organizer mode.
    func flushPendingSaves() {
        let snapshot = pendingSnapshot
        pendingSnapshot = nil
        debouncedSaveTask?.cancel()
        debouncedSaveTask = nil
        Task { [snapshot] in await performSaveIfChanged(snapshot) } // falls back to/uses live categories if nil
    }
    
    // MARK: - Category CRUD
    func addCategory(persistedInput: String) {
        let newCategory = CategoriesModel(persistedInput: persistedInput)
        categories.append(newCategory)
        normalizeCategoryOrder()
        saveHistory()
    }
    
    /// Adds an empty user category if allowed and returns its id (for autofocus)
    @discardableResult
    func addEmptyUserCategory(limit: Int = 2) -> UUID? {
        guard canAddUserCategory(limit: limit) else { return nil }
        let new = CategoriesModel(persistedInput: "")
        categories.append(new)
        normalizeCategoryOrder()
        saveHistory()
        return new.id
    }

    /// Rename category and persist. Validates and coalesces via saveHistory(). IF General is renamed...
    @MainActor
       func renameCategory(id: UUID, to newNameRaw: String) {
           let newName = newNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
           guard !newName.isEmpty else { return }
           guard let idx = categories.firstIndex(where: { $0.id == id }) else { lastError = HistoryError.categoryNotFound; return }
           
           let renamingGeneral = (id == generalCategoryID)
           categories[idx].persistedInput = newName
           validateCategory(id: id, title: newName)
           
           // If General is renamed, create a new empty "General" and repoint the anchor
           if renamingGeneral && newName != "General" {
                      let newGeneral = CategoriesModel(id: UUID(), persistedInput: "General", tiles: [])
//                      categories.insert(newGeneral, at: 0)         // temp—normalize will place correctly //FIXME: Use *.insert* or *.append*
               categories.append(newGeneral)
                      generalCategoryID = newGeneral.id            // didSet also normalizes (see below)
           }
           
           normalizeCategoryOrder()
           saveHistory()
       }

       /// Delete a user-defined category. Tiles are moved to Archive first (safe).
       @discardableResult
       func deleteCategory(id: UUID) -> Bool {
           // 1) Prevent permanently deleting anchors
           guard id != generalCategoryID, id != archiveCategoryID else { return false }
           guard
               let delIdx = categories.firstIndex(where: { $0.id == id }),
               let archIdx = categories.firstIndex(where: { $0.id == archiveCategoryID })
           else { lastError = HistoryError.categoryNotFound ; return false }

           // 2) Move tiles to Archive, "top locally" first
           let moving = categories[delIdx].tiles
           if !moving.isEmpty {
               categories[archIdx].tiles.insert(contentsOf: moving, at: 0)
               applyCaps(afterInsertingIn: archIdx)                         // 3) Trims and mirrors to actor
               
               //FIXME: This or
//               let arch = categories.first(where: { $0.id == archiveCategoryID })?.tiles ?? []
//               Task { await archiveActor.saveArchivedTiles(arch) }
               
               //FIXME: This? Which acts as we need it to?
           }

           categories.remove(at: delIdx)
           normalizeCategoryOrder()
           saveHistory()
           return true
       }

    // MARK: - Tiles API
    /// Called by Focus on completion; safe regardless of UI order (uses IDs).
    func addToHistory(_ newTile: TileM, to categoryID: UUID) {
        guard let index = categories.firstIndex(where: {  categoryItem in       // $0.id == categoryID
            categoryItem.id == categoryID
        }) else {
            debugPrint("HistoryVM.addToHistory] Category ID not found. Tile not added.")
            self.lastError = HistoryError.categoryNotFound
            return
        }
        /// Newest-first for UI display; enforce caps (Archive = 200, General and user-defined=10);
        categories[index].tiles.insert(newTile, at: 0)
        applyCaps(afterInsertingIn: index)
        saveHistory()
        /// If you do want a click here later, trigger it from the view after a successful action using your HapticsService env object, not from the VM
    }
    
    // MARK: valid target to call to move tiles within categories
    // Enforced (yes #2)
    func moveTile(_ tile: TileM, from fromID: UUID, to toID: UUID) {
        Task {
            do { try await moveTileThrowing(tile, from: fromID, to: toID) }
            catch { await MainActor.run { self.lastError = error } }
        }
    }

    func undoLastMove() {
        guard let move = lastUndoableMove else { return }
        Task {
            do {
                try await moveTileThrowing(move.tile, from: move.to, to: move.from)
                await MainActor.run { self.lastUndoableMove = nil }
            } catch {
                debugPrint("[HistoryVM.undoLastMove] error: ", error)
                await MainActor.run { self.lastError = error }
            }
        }
    }
    
    /// UI-friendly sugar for cross-category moves that funnels to the canonical thrower.
    /// Keeps call sites readable without duplicating core logic.
    func moveTileBetweenCategories(_ tile: TileM, from sourceCategoryID: UUID, to destinationCategoryID: UUID) {
        Task {
            do { try await moveTileThrowing(tile, from: sourceCategoryID, to: destinationCategoryID) }
            catch { await MainActor.run { self.lastError = error } }
        }
    }
    
    // MARK: Wrapper for call-site (RootView) clarity
    /// Reorder tiles within the given category. Validates, re-applies caps, persists.
    // (yes #2)
    func reorderTiles(_ newOrder: [TileM], in categoryID: UUID){
        guard let idx = categories.firstIndex(where: { $0.id == categoryID } ) else { return }
        categories[idx].tiles = newOrder
        applyCaps(afterInsertingIn: idx)
        saveHistory()           // VM decides *when* to persist
    }
    
    //(yes #2)
    /// Replace an entire category’s tiles (e.g., within-category reorder).
    func updateTiles(in categoryID: UUID, to newTiles: [TileM]) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
            categories[index].tiles = newTiles
            /// does the Archive=200 / General+2=10 trims
            applyCaps(afterInsertingIn: index)
            saveHistory()       /// Persist change
        }
    
    /// If a VC provides a full category order, we still re-assert canonical order afterward.
    func reorderCategories(_ newOrder: [CategoriesModel]) {
        categories = newOrder
        normalizeCategoryOrder()            // General first, Archive last
        saveHistory()
    }
    
    /// Validation function to be called from the view
    // FIXME: Needed?
    func validateCategory(id: UUID, title: String) {
        let messages = title.categoryTitleMessages
        if messages.isEmpty { categoryValidationMessages.removeValue(forKey: id) } else { categoryValidationMessages[id] = messages }
    }
    
    // MARK: Caps & Archive sync
    /// Cap rules for all categories
    private func applyCaps(afterInsertingIn idx: Int) {
        let catID = categories[idx].id
        
        // 1) Archive cap: 200 (dropping oldest to bottom)
        if catID == archiveCategoryID {
            let overflow = categories[idx].tiles.count - tileSoftCap    // tileSoftCap == 200
            if overflow > 0 {
                categories[idx].tiles.removeLast(overflow)
                tileLimitWarning = true                             // An FYI for the user
            }
            // Keep ArchiveActor authoritative
            let intoArchive = categories[idx].tiles
            Task { await archiveActor.saveArchivedTiles(intoArchive) }
            return
        }

        // 2) Build the dynamic "capped@10" set: General + first two user-defined categories
        //    (user-defined = not General, not Archive). Uses current array order.
        let userIDs = categories
            .map(\.id)
            .filter { $0 != generalCategoryID && $0 != archiveCategoryID }

        var capped10 = Set<UUID>()
        capped10.insert(generalCategoryID)
        for id in userIDs.prefix(2) { capped10.insert(id) }

        if capped10.contains(catID) {
            let overflow = categories[idx].tiles.count - 10
            if overflow > 0 { categories[idx].tiles.removeLast(overflow) }
        }
    }
    
    
   // MARK: Utilities / Convenience
    /// User-defined categories (not General/Archive)
//       var userCategoryIDs: [UUID] {
//           categories.map(\.id).filter { $0 != generalCategoryID && $0 != archiveCategoryID }
//       }
    
    var userDefinedCategoryCount: Int {
//        categories.filter { $0.id != generalCategoryID && $0.id != archiveCategoryID }.count
        userCategoryIDs.count
    }
    
    func canAddUserCategory(limit: Int = 2) -> Bool {
        userDefinedCategoryCount < limit
    }

//       func name(for id: UUID) -> String {
//           categories.first(where: { $0.id == id })?.persistedInput ?? ""
//       }
    
    /// Sets automatic "General" category aka "bootstrapping"
    func ensureGeneralCategory(named name: String = "General") {
        let generalID = generalCategoryID
        if !categories.contains(where: { generalCategoryItem in generalCategoryItem.id == generalID }) {
            let new = CategoriesModel(id: generalID, persistedInput: name)
            categories.append(new)                                                      //FIXME: use `.insert(new, at: 0)` instead?
//            debugPrint("[HistoryVM.ensureGeneralCategory] error creating 'General'")
            normalizeCategoryOrder()
            saveHistory()
        }
    }
    
    // MARK: - Sets automatic Archive category aka "bootstrapping"
    func ensureArchiveCategory(named name: String = "Archive") {
        let archiveID = archiveCategoryID
        if !categories.contains(where: { archiveCategoryItem in archiveCategoryItem.id == archiveID }) {
            let new = CategoriesModel(id: archiveID, persistedInput: name)
            categories.append(new)                                                  //FIXME: use `.insert(new, at: 0)` instead?
//            debugPrint("[HistoryVM.ensureArchiveCategory] error creating 'Archive'")
            normalizeCategoryOrder()
            saveHistory()
        }
    }
    
    // RESETS all categories: clears model first; persists a cleared list; clear storage safely: see PersistenceActor
    func clearHistory() {
        categories = []
        saveHistory()
        Task {  await persistence.clear(storageKey); await archiveActor.clearArchive() }
    }
    
    // MARK: - Throwing save (direct)
    func saveHistoryThrowing() async throws {
        try await persistence.write(sanitizedForSave(categories), to: storageKey)
    }
    
    // MARK: - Convenience throwers for call sites that want explicit errors
    func addToHistoryThrowing(_ tile: TileM, to categoryID: UUID) async throws {
        guard let index = categories.firstIndex(where: {  categoryItem in categoryItem.id == categoryID }) else {
            debugPrint("HistoryVM.addToHistory] Category ID not found. Tile not added.")
            throw HistoryError.categoryNotFound
        }
        categories[index].tiles.insert(tile, at: 0)
        applyCaps(afterInsertingIn: index)
        saveHistory()
    }
    
    // (yes #2)
    /// For cross-category moves: awaiting archive persistence before returning
    func moveTileThrowing(_ tile: TileM, from fromID: UUID, to toID: UUID) async throws {
        guard
            let fromIndex = categories.firstIndex(where: { $0.id == fromID }),
            let toIndex = categories.firstIndex(where: { $0.id == toID }),
            let tileIndex = categories[fromIndex].tiles.firstIndex(of: tile)
        else { debugPrint("[HistoryVM.moveTileThrowing //core] Category ID not found. Tile not added."); throw HistoryError.moveFailed }
        
        let moving = categories[fromIndex].tiles.remove(at: tileIndex)
        categories[toIndex].tiles.insert(moving, at: 0)
        applyCaps(afterInsertingIn: toIndex)
        
        // If Archive is involved, mirror the authoritative store
        if fromID == archiveCategoryID || toID == archiveCategoryID {
            let intoArchive = categories.first(where: { $0.id == archiveCategoryID })?.tiles ?? []
            Task { await archiveActor.saveArchivedTiles(intoArchive) }
        }
        
        saveHistory()
        lastUndoableMove = (moving, fromID, toID)
        
        // Auto-clear undo affordance
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.lastUndoableMove = nil
        }
    }
}
