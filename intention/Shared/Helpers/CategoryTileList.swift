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
    
    let tileDropHandler: TileDropHandler
    let moveTile: (TileM, UUID, UUID) async -> Void

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
                        // Avoids force-casting, registers a Data representation with a UTI (public.data), expected by `.onDrop`
                        //FIXME: use the Task helper function?
                        if let data = try? JSONEncoder().encode(dragItem) {
                            let provider = NSItemProvider()
                            provider.registerDataRepresentation(forTypeIdentifier: "puclic.data", visibility: .all) { completion in
                                completion(data, nil)
                                return nil
                            }
                            return provider
                        }
                        return NSItemProvider()
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = categoryItem.tiles.firstIndex(of: tile) {
                                withAnimation {
                                    categoryItem.tiles.remove(at: index)
                                    saveHistory()
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

