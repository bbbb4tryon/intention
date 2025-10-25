//
//  CategoryTileList.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

// Rows only -> movement handled by VM via `.dropDestination`
struct CategoryTileList: View {
    @Binding var category: CategoriesModel
    @EnvironmentObject var viewModel: HistoryVM
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.editMode) private var editMode
    let isArchive: Bool
    //    let saveHistory: () -> Void
    //    let palette: ScreenStylePalette
    //    let fontTheme: AppFontTheme
    //
    //        .font(fontTheme.toFont(.subheadline))
    
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        if category.tiles.isEmpty {
            theme.styledText(isArchive ? "No archived items yet." : "Completed", as: .caption, in: screen)
                .foregroundStyle(textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(p.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            LazyVStack(spacing: 12) {
                ForEach(category.tiles, id: \.id) { tile in
                    VStack(spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            T(tile.text, .body)
                                .foregroundStyle(p.surface)
                                .multilineTextAlignment(.leading)
                            
                            //                        if isArchive {
                            //                            Image(systemName: "archivebox")
                            //                                .imageScale(.small)
                            //                                .secondaryActionStyle(screen: screen)
                            //                                .frame(maxWidth: .infinity)
                            //                        }
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .draggable(DragPayload(tile: tile, from: category.id))
                        .swipeActions(edge: .trailing, allowsFullSwipe: !isArchive) {
                            if !isArchive {
                                Button(role: .destructive) {
                                    if let idx = category.tiles.firstIndex(of: tile) {
                                        category.tiles.remove(at: idx)
                                        // Persist via VM so caps & signatures are respected
                                        viewModel.updateTiles(in: category.id, to: category.tiles)
                                    }
                                } label: { Label("Delete", systemImage: "trash") } //FIXME: how to conform to the thememanager?
                                
                                Button {
                                    Task {
                                        do {
                                            try await viewModel.moveTileThrowing(tile, from: category.id, to: viewModel.archiveCategoryID)
                                        } catch { viewModel.lastError = error }
                                    }
                                } label: { Label("Archive", systemImage: "archivebox") }
                            }
                        }
                        // Per-tile light tan separator
                        if tile.id != category.tiles.last?.id {
                            Rectangle()
                                .fill(Color.intTan)         // light tan between tiles
                                .frame(height: 1)
                                .padding(.leading, 6)       // optional indent to look lighter
                                .padding(.trailing, 6)
                                .padding(.top, 6)
                        }
                    }
                }
            }
            // dropDestination applies to the LazyVStack
            .dropDestination(for: DragPayload.self) { items, _ in
                guard let payload = items.first else { return false }
                // from == category.id, lets sthe organizer or per-category reorder handle it.
                guard payload.from != category.id else { return false }
                Task {
                    do { try await viewModel.moveTileThrowing(payload.tile, from: payload.from, to: category.id) }
                    catch { viewModel.lastError = error }
                }
                return true
            }
        }
    }
}
