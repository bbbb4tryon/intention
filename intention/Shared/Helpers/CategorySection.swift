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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CategoryHeaderRow(
                categoryItem: $categoryItem,
                palette: palette,
                fontTheme: fontTheme,
                newTextTiles: $newTextTiles
            )

            CategoryTileList(
                categoryItem: $categoryItem,
                palette: palette,
                fontTheme: fontTheme,
                saveHistory: saveHistory
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}


