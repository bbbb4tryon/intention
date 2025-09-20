//
//  extension_HistoryVM.swift
//  intention
//
//  Created by Benjamin Tryon on 9/19/25.
//

import SwiftUI

extension HistoryVM {
    var sortedCategories: [CategoriesModel] {
        let isArchive: Bool
        categories.sorted {
            // non-archive first, Archive always last
            let aRank = $0.isArchive ? 1 : 0
            let bRank = $1.isArchive ? 1 : 0                                    // $0, then $1
            if aRank != bRank { return aRank < bRank }
            let aName = $0.persistedInput
            let bName = $1.persistedInput
            return $0.title?.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }
}
