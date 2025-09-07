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

/// Single source of truth for category IDs
/// Deinit/cleanup: rely on the lifecycle flush you already added (scenePhase .inactive / .background) and your explicit UI boundaries (e.g., “Done” in organizing
@MainActor
final class HistoryVM: ObservableObject {   
    @Published var categoryValidationMessages: [UUID: [String]] = [:]           /// Validate category text changes
    @Published var categories: [CategoriesModel] = []
    @Published var tileLimitWarning: Bool = false
    @Published var lastUndoableMove: (tile: TileM, from: UUID, to: UUID)? = nil
    @Published var lastError: Error?
    
    private let persistence: PersistenceActor
    private let archiveActor = ArchiveActor()
    private let storageKey = "categoriesData"
    private let tileSoftCap = 200
    private var pendingSnapshot: [CategoriesModel]? = nil
    private var debouncedSaveTask: Task<Void, Never>? = nil     ///Coalesced save task; only latest survives
    private var lastSavedSignature: Int = 0                     /// VM computes a lightweight signature and coalesces writes
    private let saveDebouncedDelayNanos: UInt64 = 300_000_000   /// 300 ms
    
    
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

    /// `saveHistory` calls keep storage synced, the program will rehydrate using `loadHistory()` on launch only, don't watch `categoryData`
    // Don't use any `onChange`
    init(persistence: PersistenceActor) {
        self.persistence = persistence
        Task {  await loadHistory() }
    }
    
    private func loadHistory() async {
        do {
              // 1) Load categories from disk
              if let loaded: [CategoriesModel] = try await persistence.readIfExists([CategoriesModel].self, from: storageKey) {
                  self.categories = loaded
              } else {
                  self.categories = []
              }

              // 2) Reconcile built-in IDs by name (if present in loaded data)
              if let g = categories.first(where: { $0.persistedInput == "General" }) {
                  generalCategoryID = g.id
              }
              if let a = categories.first(where: { $0.persistedInput == "Archive" }) {
                  archiveCategoryID = a.id
              }

              // 3) Ensure both built-ins exist using the reconciled IDs
              if !categories.contains(where: { $0.id == generalCategoryID }) {
                  categories.insert(CategoriesModel(id: generalCategoryID, persistedInput: "General"), at: 0)
              }
              if !categories.contains(where: { $0.id == archiveCategoryID }) {
                  categories.append(CategoriesModel(id: archiveCategoryID, persistedInput: "Archive"))
              }

              // 4) Hydrate archive tiles (now that the archive ID is canonical)
              let archived = await archiveActor.loadArchivedTiles()
              if let idx = categories.firstIndex(where: { $0.id == archiveCategoryID }) {
                  categories[idx].tiles = archived
              }

              // 5) Persist if anything changed during steps 2–4
              saveHistory()

          } catch {
              debugPrint("[HistoryVM.loadHistory] error:", error)
              await MainActor.run { self.lastError = error }
          }
    }
    
    func reconcileAndEnsureBuiltIns() {
        // 1) If categories already contain built-ins, prefer those IDs and write them back to AppStorage.
        if let g = categories.first(where: { $0.persistedInput == "General" }) {
            generalCategoryID = g.id
        }
        if let a = categories.first(where: { $0.persistedInput == "Archive" }) {
            archiveCategoryID = a.id
        }

        // 2) Ensure both exist using the canonical IDs (lazily created if empty).
        if !categories.contains(where: { $0.id == generalCategoryID }) {
            categories.insert(CategoriesModel(id: generalCategoryID, persistedInput: "General"), at: 0)
        }
        if !categories.contains(where: { $0.id == archiveCategoryID }) {
            categories.append(CategoriesModel(id: archiveCategoryID, persistedInput: "Archive"))
        }
        // the debounced/immediate server
        saveHistory()
    }
    
    // Writes only if content changed since last success - if `snapshot` is nil, uses live `categories`
    private func performSaveIfChanged(_ snapshot: [CategoriesModel]? = nil) async {
        let toWrite = snapshot ?? categories
        let signature = saveSignature(for: toWrite)
        guard signature != lastSavedSignature else { return }
        do {
            try await persistence.write(toWrite, to: storageKey)
            lastSavedSignature = signature
        } catch {
            debugPrint("[HistoryVM.performSaveIfChanged] error: ", error)
            await MainActor.run { self.lastError = HistoryError.saveHistoryFailed }
        }
    }
    private func saveSignature(for categories: [CategoriesModel]) -> Int {
        var acc = categories.count
        for cat in categories {
            acc = acc &* 31 &+ cat.id.hashValue &+ cat.tiles.count  //// Mixes ID + tile count
        }
        return acc
    }
    
    
    // MARK: - Sets automatic "General" category aka "bootstrapping"
    func ensureGeneralCategory(named name: String = "General") {
        let generalID = generalCategoryID
        if !categories.contains(where: { generalCategoryItem in generalCategoryItem.id == generalID }) {
            let new = CategoriesModel(id: generalID, persistedInput: name)
            categories.insert(new, at: 0)
            debugPrint("HistoryVM.ensureGeneralCategory: created 'General'")
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
                saveHistory(immediate: true)
            } catch {
                debugPrint("[HistoryVM.limitCheck] offload error: ", error)
                await MainActor.run { self.lastError = HistoryError.saveHistoryFailed   }
            }
        }
    }
    
    // MARK: - Non-throwing convenience (fire-and-forget)
    /// Non-throwing wrapper, background with a UI signal; catch internally, debugPrints, sets VM lasterror; saveHistory() calls saveHistoryThrowing() inside a Task
    /// Save the current categories array -> wrapper of PersistenceActor.saveHistory
    /// Public entry: schedule or force-save now.
    /// Call with `immediate: true` when the user completes an explicit action (e.g., Done, drop ended).
    func saveHistory(immediate: Bool = false) { //wrapper
        if immediate {
            let snapshot = categories               // Capture current state and write right away
            pendingSnapshot = nil
            debouncedSaveTask?.cancel()
            debouncedSaveTask = nil
            Task { await performSaveIfChanged(snapshot) }
        } else {
            scheduleDebouncedSave()
        }
    }
    
    private func scheduleDebouncedSave() {
        let snapshot = categories       // Capture now; UI may keep mutating
        pendingSnapshot = snapshot

        debouncedSaveTask?.cancel()
        debouncedSaveTask = Task { [weak self, snapshot ] in
        // Coalesce bursts of calls into one
            guard let self else { return }
            try? await Task.sleep(nanoseconds: saveDebouncedDelayNanos)
            await self.performSaveIfChanged(snapshot)
            await MainActor.run { self.pendingSnapshot = nil }
        }
    }
    
    // MARK: - Forces any pending debounced save to run now
    /// Cancels the debounce and forces the latest pending snapshot (or live state) to disk now
    func flushPendingSaves() {
        // Runs any pending debounce, immediate save and cancel
        let snapshot = pendingSnapshot
        pendingSnapshot = nil
//        if debouncedSaveTask != nil {
            debouncedSaveTask?.cancel()
            debouncedSaveTask = nil
        Task { [snapshot] in await performSaveIfChanged(snapshot) } // uses live categories if nil
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
        /// If you do want a click here later, trigger it from the view after a successful action using your HapticsService env object, not from the VM
    }
    
    
    // MARK: - Add a new category
    func addCategory(persistedInput: String){
        let newCategory = CategoriesModel(persistedInput: persistedInput)
        categories.append(newCategory)
        saveHistory()
    }
    
    // MARK: Category logic rules where the data lives
    /// Excluding built-ins, user-defined category limits
    var userDefinedCategoryCount: Int {
        categories.filter { $0.id != generalCategoryID && $0.id != archiveCategoryID }.count
    }
    
    func canAddUserCategory(limit: Int = 2) -> Bool {
        userDefinedCategoryCount < limit
    }
    /// Adds an empty user category if allowed and returns its id (for autofocus)
    @discardableResult
    func addEmptyUserCategory(limit: Int = 2) -> UUID? {
        guard canAddUserCategory(limit: limit) else { return nil }
        let new = CategoriesModel(persistedInput: "")
        categories.append(new)
        saveHistory()
        return new.id
    }
    
    // MARK: - Validation function to be called from the view
    func validateCategory(id: UUID, title: String) {
        let messages = title.categoryTitleMessages
        if messages.isEmpty {
            categoryValidationMessages.removeValue(forKey: id)
        } else {
            categoryValidationMessages[id] = messages
        }
    }
    
    
    // MARK: Throwing core (UI path)
    // MARK: valid target to call to move tiles within categories
    func moveTile(_ tile: TileM, from fromID: UUID, to toID: UUID) async throws {
        guard
            let fromIndex = categories.firstIndex(where: { $0.id == fromID }),
            let toIndex = categories.firstIndex(where: { $0.id == toID }),
            let tileIndex = categories[fromIndex].tiles.firstIndex(of: tile)
        else {
            debugPrint("Move failed: could not locate source or destination HistoryVM.moveTile")
            throw HistoryError.moveFailed
        }
        
        let movingTile = categories[fromIndex].tiles.remove(at: tileIndex)
        categories[toIndex].tiles.insert(movingTile, at: 0)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        try await saveHistoryThrowing()
        lastUndoableMove = (movingTile, fromID, toID)
        
        /// Clear undo after 3s
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.lastUndoableMove = nil         // clear undo after 3s if not acted upon (via toast)
        }
    }
    
    func undoLastMove() {
        guard let move = lastUndoableMove else { return }
        Task {
            do {
                try await moveTileThrowing(move.tile, from: move.to, to: move.from)
                self.lastUndoableMove = nil
            } catch {
                debugPrint("[HistoryVM.undoLastMove] error: ", error)
                self.lastError = error
            }
        }
    }
    
    func updateTiles(in categoryID: UUID, to newTiles: [TileM]) {
        if let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].tiles = newTiles
            saveHistory()       /// Persist change
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
    func saveHistoryThrowing() async throws { //core
        try await persistence.write(categories, to: storageKey)
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
            debugPrint("HistoryVM.moveTileThrowing //core] Category ID not found. Tile not added.")
            throw HistoryError.moveFailed
               }
               let moving = categories[fromIndex].tiles.remove(at: tileIndex)
               categories[toIndex].tiles.insert(moving, at: 0)
               try await saveHistoryThrowing()
    }
    
    func autoSaveIfNeeded() {
        Task {
            do { try await saveHistoryThrowing()    }
            catch {
                debugPrint("[HistoryVM.autoSaveIfNeeded] error: ", error)
                self.lastError = error
            }
        }
    }
}
