//
//  CategorySection.swift
//  intention
//
//  Created by Benjamin Tryon on 7/21/25.
//

import SwiftUI

struct CategorySection: View {
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    @Binding var newTextTiles: [UUID: String]
    let saveHistory: () -> Void
    let isArchive: Bool
    var autoFocus: Bool = false
    @State private var collapsed: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CategoryHeaderRow(
                categoryItem: $categoryItem,
                palette: palette,
                fontTheme: fontTheme,
                newTextTiles: $newTextTiles,
                saveHistory: saveHistory,
                isArchive: isArchive,
                autoFocus: autoFocus
            )
            
            if !collapsed.contains(categoryItem.id) {
                CategoryTileList(
                    categoryItem: $categoryItem,
                    palette: palette,
                    fontTheme: fontTheme,
                    saveHistory: saveHistory,
                    isArchive: isArchive
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}


