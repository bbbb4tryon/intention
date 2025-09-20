//
//  CategoryTileList.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct CategoryTileList: View {
    @EnvironmentObject var viewModel: HistoryVM
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    let saveHistory: () -> Void
    let isArchive: Bool
    
    var body: some View {
        if categoryItem.tiles.isEmpty {
            VStack {
                Text("Completed Intentions")
                    .font(fontTheme.toFont(.subheadline))
                    .foregroundStyle(palette.textSecondary)
            }
            .background(isArchive ? Color.secondary.opacity(0.08) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isArchive ? Color.secondary.opacity(0.12) : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            LazyVStack(spacing: 8) {
                ForEach(categoryItem.tiles, id: \.id) { tile in
                    HStack {
                        Text(tile.text)
                            .font(fontTheme.toFont(.body))
                            .foregroundStyle(palette.text)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.surface.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .draggable(DragPayload(tile: tile, from: categoryItem.id))

                    .swipeActions(edge: .trailing, allowsFullSwipe: !isArchive) {
                        if !isArchive {
                            Button(role: .destructive) {
                                if let index = categoryItem.tiles.firstIndex(where: { $0.id == tile.id }) {
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
            .allowsHitTesting(!isArchive)   // Archive is read-only
            .opacity(isArchive ? 0.9 : 1.0)
            .dropDestination(for: DragPayload.self) { items, _ in
                guard let payload = items.first else { return false }
                if payload.from == categoryItem.id { return false } // same bucket; handled by normal reordering
                Task {
                    do {
                        try await viewModel.moveTileThrowing(payload.tile,
                                                             from: payload.from,
                                                             to: categoryItem.id)
                        saveHistory()
                    } catch {
                        viewModel.lastError = error
                    }
                }
                return true
            }
        }
    }
}
