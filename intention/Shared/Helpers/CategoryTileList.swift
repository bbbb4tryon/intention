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
    
    /// Theme hooks
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let dividerRects = Color(red: 0.878, green: 0.847, blue: 0.796)
    
    // MARK: - Computed helpers
    private var isEmpty: Bool {
        category.tiles.isEmpty
    }
    
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
    
    private func isExpanded(for tile: TileM) -> Bool {
        expandedMoveRowID == tile.id
    }
    
    private func toggleMoveBar(for tile: TileM) {
        withAnimation {
            expandedMoveRowID = (expandedMoveRowID == tile.id ? nil : tile.id)
        }
    }
    
    private var archiveAlertBinding: Binding<Bool> {
        Binding(
            get: { confirmArchiveFor != nil },
            set: { if !$0 { confirmArchiveFor = nil }}
        )
    }
    
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { confirmDeleteFor != nil },
            set: { if !$0 { confirmDeleteFor = nil }}
        )
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if isEmpty {
                emptyState
            } else {
                tilesLazyStack
            }
        }
        .alert(
            "Permanently archive?",
            isPresented: archiveAlertBinding,
            actions: archiveAlertActions,
            message: archiveAlertMessage
        )
        .alert("Delete this tile?",
               isPresented: deleteAlertBinding,
               actions: deleteAlertActions,
               message: deleteAlertMessage
        )
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        T(isArchive ? "No archived items yet." : "Completed", .caption)
            .foregroundStyle(textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(p.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    // MARK: tiles stack
    private var tilesLazyStack: some View {
        LazyVStack(spacing: 12) {
            ForEach(category.tiles, id: \.id) { tile in
                VStack(spacing: 0) {
                    tileRow(for: tile)
                    
                    if isExpanded(for: tile) {
                        MoveChipRow(
                            tile: tile,
                            sourceCategoryID: category.id,
                            isArchiveList: isArchive,
                            onArchiveConfirm: { tileToArchive, sourceID in
                                confirmArchiveFor = (tileToArchive, sourceID)
                            },
                            onMovedNonArchive: {
                                withAnimation { expandedMoveRowID = nil }
                            }
                        )
                        .environmentObject(theme)
                        .environmentObject(viewModel)
                    }
                    
                    if !isLast(tile) {
                        separator
                    }
                }
            }
        }
        // dropDestination applied to the LazyVStack
        .dropDestination(for: DragPayload.self) { items, _ in
            guard let payload = items.first else { return false }
            // from == category.id lets the organizer or per-category reorder handle it
            guard payload.sourceCategoryID != category.id else { return false }
            
            Task {
                if category.id == viewModel.archiveCategoryID {
                    // archive path: immediate persist through thrower
                    do {
                        try await viewModel.moveTileThrowing(
                            payload.tile,
                            fromCategory: payload.sourceCategoryID,
                            toCategory: category.id
                        )
                    } catch {
                        viewModel.lastError = error;
                        debugPrint("[CategoryTileList] dropDestination failed")
                    }
                } else {
                    // non-archive path: dalayed persist + a window of undo-ness
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
    
    // MARK: - tile rows + separator
    private func tileRow(for tile: TileM) -> some View {
        HStack(alignment: .firstTextBaseline) {
            T(tile.text, .tile)
                .foregroundStyle(p.text)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
        }
        .padding(10)
        .background(p.surfaces, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .draggable(DragPayload(tile: tile, sourceCategoryID: category.id))
        // swipe right - opens Move bar
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            moveSwipeButtons(for: tile)
        }
        // swipe left - Delete || Archive
        .swipeActions(edge: .trailing, allowsFullSwipe: !isArchive) {
            destructiveSwipeButtons(for: tile)
        }
    }
    
    private var separator: some View {
        Rectangle()
        // light tan between tiles
            .fill(dividerRects)
            .frame(height: 1)
            .padding(.leading, 6)
            .padding(.trailing, 6)
            .padding(.top, 6)
    }
    
    
    // MARK: - Swipe helpers
    @ViewBuilder
    private func moveSwipeButtons(for tile: TileM) -> some View {
        Button(
            role: .none,
            action: { toggleMoveBar(for: tile) }
        ) {
            HStack {
                Image(systemName: "arrow.right.circle")
                T("Move", .action)
            }
        }
    }
    
    @ViewBuilder
    private func destructiveSwipeButtons(for tile: TileM) -> some View {
        if !isArchive {
            
            // Delete (with confirm alert)
            Button(
                role: .destructive,
                action: {
                    // alert does actual removal
                    confirmDeleteFor = (tile, category.id)
                }
            ) {
                HStack {
                    Image(systemName: "trash")
                    T("Delete", .action)
                }
            }
            
            // Archive (with confirm alert)
            Button(
                role: .none,
                action: {
                    confirmArchiveFor = (tile, category.id)
                }
            ) {
                HStack {
                    Image(systemName: "archivebox")
                    T("Archive", .action)
                }
            }
        }
    }
    
    // MARK: - Alert content helpers
    @ViewBuilder
    private func archiveAlertActions() -> some View {
        Button("Cancel", role: .cancel) { }
        
        Button("Archive", role: .destructive) {
            if let arch = confirmArchiveFor {
                Task {
                    do {
                        try await viewModel.moveTileThrowing(
                            arch.tile,
                            fromCategory: arch.sourceID,
                            toCategory: viewModel.archiveCategoryID
                        )
                    } catch {
                        viewModel.lastError = error
                        debugPrint("[CategoryTileList] Archive confirm failed")
                    }
                }
            } else {
                debugPrint("[CategoryTileList] Archive confirm fired but confirmArchiveFor is nil")
            }
            confirmArchiveFor = nil
            withAnimation { expandedMoveRowID = nil }
        }
    }
    
    @ViewBuilder
    private func archiveAlertMessage() -> some View {
        Text("This cannot be undone.")
    }
    
    @ViewBuilder
    private func deleteAlertActions() -> some View {
        Button("Cancel", role: .cancel) { }
        
        Button("Delete", role: .destructive) {
            if let del = confirmDeleteFor,
               let idx = category.tiles.firstIndex(of: del.tile) {
                category.tiles.remove(at: idx)
                viewModel.reorderTiles(category.tiles, in: del.sourceID)
            } else {
                debugPrint("[CategoryTileList] Delete confirm fired but tile not found")
            }
            confirmDeleteFor = nil
            withAnimation { expandedMoveRowID = nil }
        }
    }
    
    @ViewBuilder
    private func deleteAlertMessage() -> some View {
        Text("This cannot be undone.")
    }
}

// MARK: MoveChipRow struct
private struct MoveChipRow: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var viewModel: HistoryVM
    
    let tile: TileM
    let sourceCategoryID: UUID
    let isArchiveList: Bool
    
    /// Called when user chooses Archive as destination (we just set state, alerts do work)
    var onArchiveConfirm: (TileM, UUID) -> Void
    
    /// Called after a non-archive move completes (to collapse the bar)
    var onMovedNonArchive: () -> Void
    
    /// Theme hooks
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories) { dest in
                    if dest.id != sourceCategoryID {
                        destinationChip(for: dest)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(p.surfaces.opacity(0.8), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    //    private func moveDestinationChip(for tile: TileM,
    //                                     destination dest: CategoriesModel) -> some View {
    @ViewBuilder
    private func destinationChip(for dest: CategoriesModel) -> some View {
        let isArchiveDest = dest.id == viewModel.archiveCategoryID
        
        Button(
            role: isArchiveDest ? .destructive : .none,
            action: {
                if isArchiveDest {
                    // Archive destination: confirm first, then immediate persist via VM
                    onArchiveConfirm(tile, sourceCategoryID)
                    //                if confirmArchiveFor == nil {
                    //                    confirmArchiveFor = (tile, category.id)
                    //                } else {
                    //                    debugPrint("[CategoryTileList] Archive confirm already pending (chip)")
                    //                }
                } else {
                    // Non-archive destination: delayed persist + undo window
                    viewModel.moveTileWithUndoWindow(
                        tile,
                        fromCategory: sourceCategoryID,
                        toCategory: dest.id
                    )
                    onMovedNonArchive()
                }
            }
        ) {
            HStack {
                if isArchiveDest {
                    Image(systemName: "archivebox")
                } else {
                    Image(systemName: "")
                }
                T(dest.persistedInput.ifEmpty("Untitled"), .action)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isArchiveDest
                ? p.accent.opacity(0.20)
                : p.surfaces.opacity(0.15),
                in: Capsule()
            )
        }
    }
}

private extension String {
    func ifEmpty(_ replacement: String) -> String { isEmpty ? replacement : self }
}
