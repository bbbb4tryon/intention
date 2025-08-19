//
//  CategoryTileList.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct CategoryTileList: View {
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    let saveHistory: () -> Void
    let isArchive: Bool
    
    var body: some View {
        if categoryItem.tiles.isEmpty {
            VStack {
                /// Gives archive section subtle card treatment
                Text("Tasks you intended to complete would display here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .background(isArchive ? Color.secondary.opacity(0.08) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isArchive ? Color.secondary.opacity(0.03) : .clear, lineWidth: 1)
            )
            .cornerRadius(12)
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: !isArchive) {
                        if !isArchive {
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
            }
            .padding(.horizontal)
        }
    }
}

