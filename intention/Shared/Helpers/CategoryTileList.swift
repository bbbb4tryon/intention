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
    private var isEmpty: Bool { category.tiles.isEmpty }
    private var emptyMessage: String { isArchive ? "No archived items yet." : "Completed" }
    /// All possible move destinations (excluding the current category)
    private var destinationCategories: [CategoriesModel] {
        viewModel.categories.filter { $0.id != category.id }
    }
    
    private func isLast(_ tile: TileM) -> Bool {
        tile.id == category.tiles.last?.id
    }
    private func isArchiveCategory(_ id: UUID) -> Bool {
        id == viewModel.archiveCategoryID
    }
    private func moveBarVisible(for tile: TileM) -> Bool {
        expandedMoveRowID == tile.id
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if isEmpty {
                emptyStateView
            } else {
                tilesList
            }
        }
        // MARK: - Alerts attached at root
               .alert("Permanently archive this tile?",
                      isPresented: Binding(
                       get: { confirmArchiveFor != nil },
                       set: { if !$0 { confirmArchiveFor = nil } }
                      )) {
                   Button("Cancel", role: .cancel) {}

                   Button("Archive", role: .destructive) {
                       guard let a = confirmArchiveFor else {
                           debugPrint("[CategoryTileList] Archive alert fired with nil payload")
                           return
                       }
                       Task {
                           do {
                               try await viewModel.moveTileThrowing(
                                   a.tile,
                                   fromCategory: a.sourceID,
                                   toCategory: viewModel.archiveCategoryID
                               )
                           } catch {
                               viewModel.lastError = error
                           }
                       }
                       confirmArchiveFor = nil
                       withAnimation { expandedMoveRowID = nil }
                   }
               } message: {
                   T("This cannot be undone.", .caption)
               }
               .alert("Delete this tile?",
                      isPresented: Binding(
                       get: { confirmDeleteFor != nil },
                       set: { if !$0 { confirmDeleteFor = nil } }
                      )) {
                   Button("Cancel", role: .cancel) {}

                   Button("Delete", role: .destructive) {
                       guard
                           let d = confirmDeleteFor,
                           let idx = category.tiles.firstIndex(of: d.tile)
                       else {
                           debugPrint("[CategoryTileList] Delete alert fired but tile not found")
                           confirmDeleteFor = nil
                           return
                       }

                       // Local removal then VM persist via reorderTiles
                       category.tiles.remove(at: idx)
                       viewModel.reorderTiles(category.tiles, in: d.sourceID)

                       confirmDeleteFor = nil
                       withAnimation { expandedMoveRowID = nil }
                   }
               }
           }
    //            theme.styledText(isArchive ? "No archived items yet." : "Completed", as: .caption, in: screen)
    //
    //
    //                        // Row content
    //                        HStack(alignment: .firstTextBaseline) {
    //                            T(tile.text, .tile)
    //                                .foregroundStyle(p.surface)
    //                                .multilineTextAlignment(.leading)
    //                            Spacer()
    //                        }
    //                        .padding(10)
    //                        .background(p.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    //                        .draggable(DragPayload(tile: tile, sourceCategoryID: category.id))
    //                        //
    //                        // MARK: - Swipe Right -> Move (inline chips)
    //                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
    //                            Button {
    //                                //                                expandedMoveRowID = tile.id
    //                                withAnimation { expandedMoveRowID = (expandedMoveRowID == tile.id ? nil : tile.id) }
    //                            } label: {
    //                                Label("Move", systemImage: "arrow.right.circle")
    //                            }
    //                        }
    //
    //
    //                        // MARK: - Swipe Left -> Delete + Archive (inline chips)
    //                        .swipeActions(edge: .leading, allowsFullSwipe: !isArchive) {
    //                            if !isArchive {
    //                                /* remove from category + persist via VM */
    //                                // Delete (w confirm alert)
    //                                Button(role: .destructive, action: {
    //                                    confirmDeleteFor = (tile, category.id)   // << set; alert does the work
    //                                    //                                    if let idx = category.tiles.firstIndex(of: tile) {
    //                                    //                                        category.tiles.remove(at: idx)
    //                                    //                                        // Persist via VM reorderTiles already applies caps + persists, updateTiles() & saveHistory() redundant
    //                                    //                                        viewModel.reorderTiles(category.tiles, in: category.id)
    //                                } else { debugPrint("Tiles not removed") }
    //                            }, label: {
    //                                Image(systemName: "trash")
    //                                T("Delete", .action)
    //                            }
    //                            //                            })
    //
    //                            /* move to Archive via VM */
    //                            // Archive (confirm, then immediately persist
    //                            Button {
    //                                confirmArchiveFor = (tile, category.id)
    //                                //                                    Task {
    //                                //                                        do { try await viewModel.moveTileThrowing(
    //                                //                                            tile, fromCategory: category.id, toCategory: viewModel.archiveCategoryID )}
    //                                //                                        catch { viewModel.lastError = error }
    //                                //                                    }
    //                            } label: {
    //                                Image(systemName: "archivebox")
    //                                T("Archive", .action)
    //                            }
    //                        })
    //
    //                        // MARK: - Inline Move Bar (chips)
    //                        if expandedMoveRowID == tile.id {
    //                            ScrollView(.horizontal, showsIndicators: false) {
    //                                HStack(spacing: 8) {
    //                                    // Destination chips (all categories except source)
    //                                    ForEach(viewModel.categories) { dest in
    //                                        if dest.id != category.id {
    //                                            Button {
    //                                                // Archive requires confirmation; non-archive uses undo window
    //                                                if dest.id == viewModel.archiveCategoryID {
    //                                                    confirmArchiveFor = (tile, category.id)
    //                                                } else {
    //                                                    // Non-archive: delayed persist + undo window
    //                                                    viewModel.moveTileWithUndoWindow(tile,
    //                                                                                     fromCategory: category.id,
    //                                                                                     toCategory: dest.id)
    //                                                    withAnimation { expandedMoveRowID = nil }
    //                                                }
    //                                            } label: {
    //                                                Text(dest.persistedInput)
    //                                                    .padding(.horizontal, 10)
    //                                                    .padding(.vertical, 6)
    //                                                    .background(
    //                                                        (dest.id == viewModel.archiveCategoryID ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.15),
    //                                                         in: Capsule()
    //                                                        )
    //                                            }
    //                                        }
    //                                    }
    //                                }
    //                                .padding(.horizontal, 10)
    //                                .padding(.vertical, 6)
    //                            }
    //                            .background(Color(.secondarySystemBackground),
    //                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    //                            .transition(.opacity.combined(with: .move(edge: .top)))
    //                        }
    //
    //                        // Per-tile light tan separator
    //                        if tile.id != category.tiles.last?.id {
    //                            Rectangle()
    //                                .fill(dividerRects)         // light tan between tiles
    //                                .frame(height: 1)
    //                                .padding(.leading, 6)       // optional indent to look lighter
    //                                .padding(.trailing, 6)
    //                                .padding(.top, 6)
    //                        }
    //                    }
    //                }
    //            }
    //            // dropDestination applies to the LazyVStack
    //            .dropDestination(for: DragPayload.self) { items, _ in
    //                guard let payload = items.first else { return false }
    //                // from == category.id, lets sthe organizer or per-category reorder handle it.
    //                guard payload.sourceCategoryID != category.id else { return false }
    //
    //                Task {
    //                    //                    do { try await viewModel.moveTileThrowing(payload.tile, fromCategory: payload.sourceCategoryID, toCategory: category.id) }
    //                    //                    catch { viewModel.lastError = error }
    //                    if category.id == viewModel.archiveCategoryID {
    //                        // archive path: immediate persist through thrower
    //                        try await viewModel.moveTileThrowing(
    //                            payload.tile,
    //                            fromCategory: payload.sourceCategoryID,
    //                            toCategory: category.id
    //                        )
    //                    } catch { viewModel.lastError = error }
    //                } else {
    //                    // Non-archive path: delayed persist + undo window.
    //                    await MainActor.run {
    //                        viewModel.moveTileWithUndoWindow(
    //                            payload.tile,
    //                            fromCategory: payload.sourceCategoryID,
    //                            toCategory: category.id
    //                        )
    //                    }
    //                }
    //            }
    //            return true
    //        }
    //    }
    //}
    // Alerts (no sheet): Attached to the CategoryTileList root
    //    .alert("Permanently archive this tile?",
    //           isPresented: Binding(
    //            get: { confirmArchiveFor != nil },
    //            set: { if !$0 { confirmArchiveFor = nil } }
    //           )) {
    //               Button("Cancel", role: .cancel) {}
    //               Button("Archive", role: .destructive) {
    //                   if let a = confirmArchiveFor {
    //                       Task {
    //                           do {
    //                               try await viewModel.moveTileThrowing(
    //                                a.tile,
    //                                fromCategory: a.sourceID,
    //                                toCategory: viewModel.archiveCategoryID
    //                               )
    //                           } catch { viewModel.lastError = error }
    //                       }
    //                   }
    //                   confirmArchiveFor = nil
    //                   withAnimation { expandedMoveRowID = nil }
    //               }
    //           } message: {
    //               Text("This cannot be undone.")
    //           }
    
    //           .alert("Delete this tile?",
    //                  isPresented: Binding(
    //                    get: { confirmDeleteFor != nil },
    //                    set: { if !$0 { confirmDeleteFor = nil } }
    //                  )) {
    //                      Button("Cancel", role: .cancel) {}
    //                      Button("Delete", role: .destructive) {
    //                          if let d = confirmDeleteFor,
    //                             let idx = category.tiles.firstIndex(of: d.tile) {
    //                              // Local removal then VM persist via reorderTiles
    //                              category.tiles.remove(at: idx)
    //                              viewModel.reorderTiles(category.tiles, in: d.sourceID)
    //                          }
    //                          confirmDeleteFor = nil
    //                          withAnimation { expandedMoveRowID = nil }
    //                      }
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        T(emptyMessage, .caption)
            .foregroundStyle(textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(p.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private var tilesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(category.tiles, id: \.id) { tile in
                VStack(spacing: 0) {
                    rowContent(for: tile)
                    if moveBarVisible(for: tile) {
                        moveBar(for: tile)
                    }
                    if !isLast(tile) {
                        separator
                    }
                }
            }
        }
        .dropDestination(for: DragPayload.self) { items, _ in
            handleDrop(items: items)
        }
    }
    
    private func rowContent(for tile: TileM) -> some View {
        HStack(alignment: .firstTextBaseline) {
            T(tile.text, .tile)
                .foregroundStyle(p.text)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(10)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .draggable(DragPayload(tile: tile, sourceCategoryID: category.id))
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            //                                          moveSwipeButton(for: tile)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: !isArchive) {
            if !isArchive {
                //                                              deleteSwipeButton(for: tile)
                //                                              archiveSwipeButton(for: tile)
            }
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(dividerRects)
            .frame(height: 1)
            .padding(.leading, 6)
            .padding(.trailing, 6)
            .padding(.top, 6)
    }
    
    // MARK: - Swipe buttons
    
    private func moveSwipeButton(for tile: TileM) -> some View {
        Button(action: {
            withAnimation {
                if expandedMoveRowID == tile.id {
                    expandedMoveRowID = nil
                } else {
                    expandedMoveRowID = tile.id
                }
            }
        }) {
            HStack {
                Image(systemName: "arrow.right.circle")
                T("Move", .action)
            }
        }
    }
    
    private func deleteSwipeButton(for tile: TileM) -> some View {
        Button(role: .destructive, action: {
            if confirmDeleteFor == nil {
                confirmDeleteFor = (tile, category.id)
            } else {
                debugPrint("[CategoryTileList] Delete confirm pending but not accomplished")
            }
        }) {
            HStack {
                Image(systemName: "arrow.right.circle")
                T("Move", .action)
            }
        }
    }
    
    private func archiveSwipeButton(for tile: TileM) -> some View {
        Button(role: .destructive, action: {
            if confirmArchiveFor == nil {
                confirmArchiveFor = (tile, category.id)
            } else {
                debugPrint("[CategoryTileList] Archive confirm pending but not accomplished")
            }
        }) {
            HStack {
                Image(systemName: "arrow.right.circle")
                T("Move", .action)
            }
        }
        .tint(p.accent)
    }
    
    // MARK: - Inline move bar
    
    private func moveBar(for tile: TileM) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(destinationCategories) { dest in
                    moveDestinationChip(for: tile, destination: dest)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(p.surface.opacity(0.8),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func moveDestinationChip(for tile: TileM,
                                     destination dest: CategoriesModel) -> some View {
        Button(action: {
            if isArchiveCategory(dest.id) {
                // Archive requires confirmation, never undo
                if confirmArchiveFor == nil {
                    confirmArchiveFor = (tile, category.id)
                } else {
                    debugPrint("[CategoryTileList] Archive confirm already pending (chip)")
                }
            } else {
                // Non-archive: delayed persist + undo window
                viewModel.moveTileWithUndoWindow(
                    tile,
                    fromCategory: category.id,
                    toCategory: dest.id
                )
                withAnimation { expandedMoveRowID = nil }
            }
        }) {
            HStack {
                // Optional: different icon for archive vs others
                if isArchiveCategory(dest.id) {
                    Image(systemName: "archivebox")
                } else {
                    //Image(systemName: "folder")
                }
                T(dest.persistedInput.ifEmpty("Untitled"), .action)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (isArchiveCategory(dest.id)
                 ? p.accent.opacity(0.20)
                 : p.surface.opacity(0.18)),
                in: Capsule()
            )
        }
    }
    
    // MARK: - Drag & Drop handler
    
    private func handleDrop(items: [DragPayload]) -> Bool {
        guard let payload = items.first else { return false }
        // from == category.id, let per-category reordering (if any) handle it elsewhere
        guard payload.sourceCategoryID != category.id else { return false }
        
        Task {
            if isArchiveCategory(category.id) {
                // Archive path: immediate persist through thrower
                do {
                    try await viewModel.moveTileThrowing(
                        payload.tile,
                        fromCategory: payload.sourceCategoryID,
                        toCategory: category.id
                    )
                } catch {
                    viewModel.lastError = error
                }
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


private extension String {
    func ifEmpty(_ replacement: String) -> String { isEmpty ? replacement : self }
}
