//
//  HistoryVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//


import Foundation
import SwiftUI

@MainActor
final class HistoryVM: ObservableObject {
    @Published var categories: [CategoriesModel] = []

    // AppStorage wrapper (private, not accessed directly from the view)
    // since `historyVM` is injected into `FocusSessionVM` at startup via `RootView`
    //  the `FocusSessionVM` `func checkSessionCompletion()`'s `addSession(tiles)`
    //  method successfully archives each 2-tile session in and survives app restarts:
    @AppStorage("categoriesData") private var categoryData: Data = Data()
    {   didSet  {   loadHistory()    }  }
    
    init() {
        loadHistory()
    }

    
    private func loadHistory()  {
        guard !categoryData.isEmpty else { return }
        do {
            categories = try JSONDecoder().decode([CategoriesModel].self, from: categoryData)
        } catch {
            debugPrint("HistoryVM: Failed to decode history")
        }
    }
    // MARK: persistence helper
    //FIXME: need a "background Task"?
    func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(categories)
            categoryData = encoded
        } catch {
            debugPrint("HistoryVM: Failed to encode history")
        }
    }
    
    // MARK: - Add a tile to a specific category
    func addToHistory(_ newTile: TileM, to categoryID: UUID){
        guard let index = categories.firstIndex(where: {  categoryItem in
            categoryItem.id == categoryID
        }) else {
            debugPrint("HistoryVM: Category ID not found. Tile not added.")
            return
        }
        //FIXME: Just add to top of screen or Miscellaneous?
        categories[index].tiles.insert(newTile, at: 0)  // "capped FIFO" newest-first for UI display

        saveHistory()                       // saveHistory() is inside addToHistory() to persist automatically
    }
    
    // MARK: - Add a new category
    func addCategory(persistedInput: String){
        let newCategory = CategoriesModel(persistedInput: persistedInput)
        categories.append(newCategory)
        saveHistory()
    }

    // MARK: reset all categories
    func clearHistory() {
        categories = []
        categoryData = Data() // clear storage
    }
    
    // MARK: - sets default category
    func ensureDefaultCategory(named name: String = "Miscellaneous", userService: UserService) {
        let defaultID = userService.defaultCategoryID
        
        if !categories.contains(where: { defaultCategoryItem in
            defaultCategoryItem.id == defaultID
        }) {
            let new = CategoriesModel(id: defaultID, persistedInput: name)
            categories.insert(new, at: 0)
            saveHistory()
        }
    }
}
