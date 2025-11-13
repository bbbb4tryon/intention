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
    
    // per-row expansion under a tile when you tap Move in the right-swipe
    @State private var expandedMoveRowID: UUID?   // which tile shows the move bar
    @State private var confirmArchiveFor: (tile: TileM, sourceID: UUID)?
    @State private var confirmDeleteFor:  (tile: TileM, sourceID: UUID)?
    
    let isArchive: Bool
    
    // Theme plumbing
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let dividerRects = Color(red: 0.878, green: 0.847, blue: 0.796)
    
    // MARK: - Computed helpers
    
    
    var body: some View {
        //        Group {
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
                        // Row content
                        HStack(alignment: .firstTextBaseline) {
                            T(tile.text, .tile)
                                .foregroundStyle(p.surface)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(10)
                        .background(p.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .draggable(DragPayload(tile: tile, sourceCategoryID: category.id))
                        //
                        // MARK: - Swipe Right -> Move (inline chips)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                //                                expandedMoveRowID = tile.id
                                withAnimation { expandedMoveRowID = (expandedMoveRowID == tile.id ? nil : tile.id) }
                            } label: {
                                Label("Move", systemImage: "arrow.right.circle")
                            }
                        }
                        
                        
                        // MARK: - Swipe Left -> Delete + Archive (inline chips)
                        .swipeActions(edge: .leading, allowsFullSwipe: !isArchive) {
                            if !isArchive {
                                /* remove from category + persist via VM */
                                // Delete (w confirm alert)
                                Button(role: .destructive, action: {
                                    confirmDeleteFor = (tile, category.id)   // << set; alert does the work
                                    //                                    if let idx = category.tiles.firstIndex(of: tile) {
                                    //                                        category.tiles.remove(at: idx)
                                    //                                        // Persist via VM reorderTiles already applies caps + persists, updateTiles() & saveHistory() redundant
                                    //                                        viewModel.reorderTiles(category.tiles, in: category.id)
                                } else { debugPrint("Tiles not removed") }
                            }, label: {
                                Image(systemName: "trash")
                                T("Delete", .action)
                            }
                            //                            })
                            
                            /* move to Archive via VM */
                            // Archive (confirm, then immediately persist
                            Button {
                                confirmArchiveFor = (tile, category.id)
                                //                                    Task {
                                //                                        do { try await viewModel.moveTileThrowing(
                                //                                            tile, fromCategory: category.id, toCategory: viewModel.archiveCategoryID )}
                                //                                        catch { viewModel.lastError = error }
                                //                                    }
                            } label: {
                                Image(systemName: "archivebox")
                                T("Archive", .action)
                            }
                        })
                        
                        // MARK: - Inline Move Bar (chips)
                        if expandedMoveRowID == tile.id {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    // Destination chips (all categories except source)
                                    ForEach(viewModel.categories) { dest in
                                        if dest.id != category.id {
                                            Button {
                                                // Archive requires confirmation; non-archive uses undo window
                                                if dest.id == viewModel.archiveCategoryID {
                                                    confirmArchiveFor = (tile, category.id)
                                                } else {
                                                    // Non-archive: delayed persist + undo window
                                                    viewModel.moveTileWithUndoWindow(tile,
                                                                                     fromCategory: category.id,
                                                                                     toCategory: dest.id)
                                                    withAnimation { expandedMoveRowID = nil }
                                                }
                                            } label: {
                                                Text(dest.persistedInput)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        (dest.id == viewModel.archiveCategoryID ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.15),
                                                         in: Capsule()
                                                        )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .background(Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Per-tile light tan separator
                        if tile.id != category.tiles.last?.id {
                            Rectangle()
                                .fill(dividerRects)         // light tan between tiles
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
                guard payload.sourceCategoryID != category.id else { return false }
                
                Task {
                    //                    do { try await viewModel.moveTileThrowing(payload.tile, fromCategory: payload.sourceCategoryID, toCategory: category.id) }
                    //                    catch { viewModel.lastError = error }
                    if category.id == viewModel.archiveCategoryID {
                        // archive path: immediate persist through thrower
                        try await viewModel.moveTileThrowing(
                            payload.tile,
                            fromCategory: payload.sourceCategoryID,
                            toCategory: category.id
                        )
                    } catch { viewModel.lastError = error }
                } else {
                    // Non-archive path: delayed persist + undo window.
                    await MainActor.run {
                        viewModel.moveTileWithUndoWindow(
                            payload.tile,
                            fromCategory: payload.sourceCategoryID,
                            toCategory: category.id
                        )
                    }
                }
            }
            return true
        }
    }
}
    // Alerts (no sheet): Attached to the CategoryTileList root
        .alert("Permanently archive this tile?",
               isPresented: Binding(
                get: { confirmArchiveFor != nil },
                set: { if !$0 { confirmArchiveFor = nil } }
               )) {
            Button("Cancel", role: .cancel) {}
            Button("Archive", role: .destructive) {
                if let a = confirmArchiveFor {
                    Task {
                        do {
                            try await viewModel.moveTileThrowing(
                                a.tile,
                                                                 fromCategory: a.sourceID,
                                                                 toCategory: viewModel.archiveCategoryID
                            )
                        } catch { viewModel.lastError = error }
                    }
                }
                confirmArchiveFor = nil
                withAnimation { expandedMoveRowID = nil }
            }
        } message: {
            Text("This cannot be undone.")
        }

        .alert("Delete this tile?",
               isPresented: Binding(
                get: { confirmDeleteFor != nil },
                set: { if !$0 { confirmDeleteFor = nil } }
               )) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let d = confirmDeleteFor,
                   let idx = category.tiles.firstIndex(of: d.tile) {
                    // Local removal then VM persist via reorderTiles
                    category.tiles.remove(at: idx)
                    viewModel.reorderTiles(category.tiles, in: d.sourceID)
                }
                confirmDeleteFor = nil
                withAnimation { expandedMoveRowID = nil }
            }
        }
}
}
