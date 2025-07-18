//
//  CategoryTileList.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI

struct CategoryTileList: View {
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    let saveHistory: () -> Void

    var body: some View {
        if categoryItem.tiles.isEmpty {
            Text("Tasks you intended to complete would display here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(categoryItem.tiles) { tile in
                    HStack {
                        Text(tile.text)
                            .font(fontTheme.toFont(.body))
                            .foregroundStyle(palette.text)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .onDrag {
                        let dragItem = DraggedTile(tile: tile, fromCategoryID: categoryItem.id)
                        return try! NSItemProvider(object: JSONEncoder().encode(dragItem) as NSData)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = categoryItem.tiles.firstIndex(of: tile) {
                                categoryItem.tiles.remove(at: index)
                                saveHistory()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .onDrop(of: [.data], isTargeted: nil) { providers in
                handleTileDrop(providers: providers, targetCategoryID: categoryItem.id)
            }
        }
    }
}

