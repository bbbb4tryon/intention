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
    @Binding var dropTarget: Bool
    let saveHistory: () -> Void
    let tileDropHandler: TileDropHandler
    let moveTile: (TileM, UUID, UUID) async -> Void

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
                saveHistory: saveHistory,
                tileDropHandler: tileDropHandler,
                moveTile: moveTile
            )
            .onDrop(of: [.data], isTargeted: $dropTarget) { providers in
                //FIXME: use the extracted helper????
                Task {
                    if let dragged = await tileDropHandler.handleDrop(providers: providers),
                       dragged.fromCategoryID != categoryItem.id {
                        await moveTile(dragged.tile, dragged.fromCategoryID, categoryItem.id)
                    }
                }
                return true
            }
            .background(dropTarget ? palette.accent.opacity(0.1) : Color.clear)
            .animation(.easeInOut, value: dropTarget)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

