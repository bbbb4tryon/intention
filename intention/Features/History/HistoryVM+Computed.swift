//
//  HistoryVM+Computed.swift
//  intention
//
//  Created by Benjamin Tryon on 9/19/25.
//

import SwiftUI
import Foundation

extension HistoryVM {
    
    /// IDs for user-defined categories (excludes General/Archive)
    var userCategoryIDs: [UUID] {
        categories
            .map(\.id)
            .filter { $0 != generalCategoryID && $0 != archiveCategoryID }
    }

    /// Name lookup by ID (safe default)
    func name(for id: UUID) -> String {
        categories.first(where: { $0.id == id })?.persistedInput ?? "Untitled"
    }
}

//
//    var sortedCategories: [CategoriesModel] {
//        categories.sorted { a, b in
//            // non-archive first, Archive always last
//            let aRank = (a.id == archiveCategoryID) ? 1 : 0
//            let bRank = (b.id == archiveCategoryID) ? 1 : 0
//            if aRank != bRank { return aRank < bRank }
//            // Alphabetical by persistedInput
//            return a.persistedInput.localizedCaseInsensitiveCompare(b.persistedInput) == .orderedAscending
//        }
//    }
//}
