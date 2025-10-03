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
    var body: some View {
        // FIXME: use CARD {}?
        if category.tiles.isEmpty {
            theme.styledText(isArchive ? "No archived items yet." : "Completed", as: .caption, in: screen)
                .foregroundStyle(p.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(p.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            LazyVStack(spacing: 8) {
                ForEach(category.tiles, id: \.id) { tile in
                    HStack(alignment: .firstTextBaseline) {
                        T("\(tile.text)", .body)
                            .multilineTextAlignment(.leading)
                        Spacer()
//                        if isArchive {
//                            Image(systemName: "archivebox")
//                                .imageScale(.small)
//                                .secondaryActionStyle(screen: screen)
//                                .frame(maxWidth: .infinity)
//                        }
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
                }
            }
            .dropDestination(for: DragPayload.self) { items, _ in
                 guard let payload = items.first else { return false }
                 // If from == category.id, we let the organizer or per-category reorder handle it.
                 guard payload.from != category.id else { return false }
                 Task {
                     do { try await viewModel.moveTileThrowing(payload.tile, from: payload.from, to: category.id) }
                     catch { viewModel.lastError = error }
                 }
                 return true
             }
         }
     }
    
    // MARK: - keep the buttons (accessibility/quick actions)
//    private func moveTileToTop(_ tile: TileM) {
//        var new = category.tiles
//        guard let i = new.firstIndex(of: tile) else { return }
//        let t = new.remove(at: i)
//        new.insert(t, at: 0)
//        viewModel.updateTiles(in: category.id, to: new)  // persists & caps
//    }
//
//    private func moveTileToBottom(_ tile: TileM) {
//        var new = category.tiles
//        guard let i = new.firstIndex(of: tile) else { return }
//        let t = new.remove(at: i)
//        new.append(t)
//        viewModel.updateTiles(in: category.id, to: new)  // persists & caps
//    }
//
//    private func moveTileToArchive(_ tile: TileM) {
//        Task {
//            do { try await viewModel.moveTileThrowing(tile, from: category.id, to: viewModel.archiveCategoryID) }
//            catch { viewModel.lastError = error }
//        }
//    }
 }

 /// Transferable wrapper used for SwiftUI drag/drop within History.
 /// Keeps TileM / CategoriesModel free of UI protocols.
// struct DragPayload: Transferable, Codable, Hashable {
//     let tile: TileM
//     let from: UUID
//
//     static var transferRepresentation: some TransferRepresentation {
//         CodableRepresentation(contentType: .data)
//     }
// }


//
//                                            
//                                            
//                                            
//                        if editMode?.wrappedValue.isEditing == true && !isArchive {
//                            HStack(spacing: 10) {
//                                Button { moveTileToTop(tile) } label: { Image(systemName: "square.3.layers.3d.top.filled") }
//                                Button { moveTileToBottom(tile) } label: { Image(systemName: "square.3.layers.3d.bottom.filled") }
//                                Button { moveTileToArchive(tile) } label: { Image(systemName: "archivebox") }
//                            }
//                            .buttonStyle(.borderless)
//                        }
//                    }
//                    .draggable(DragPayload(tile: tile, from: category.id))
//                    .swipeActions(edge: .trailing, allowsFullSwipe: !isArchive) {
//                        if !isArchive {
//                            Button(role: .destructive) {
//                                if let index = category.tiles.firstIndex(of: tile) {
//                                    category.tiles.remove(at: index)
//                                    saveHistory()
//                                    
//                                }
//                            } label: { Label("Delete", systemImage: "trash") }
//                        }
//                    }
//                }
//            }
//            .padding(.horizontal)
//            .allowsHitTesting(!isArchive || editMode?.wrappedValue.isEditing == true)   // Archive is read-only
//            .opacity(isArchive ? 0.9 : 1.0)
//            .dropDestination(for: DragPayload.self) { items, _ in
//                guard let payload = items.first else { return false }
//                if payload.from == category.id { return false }         // same bucket move handled by buttons
//                Task {
//                    do {
//                        try await viewModel.moveTileThrowing(payload.tile, from: payload.from, to: category.id)
//                        saveHistory()
//                    } catch {
//                        viewModel.lastError = error
//                    }
//                }
//                return true
//            }
//        }
//    }
//    
//    private func moveTileToTop(_ tile: TileM) {
//        if let idx = category.tiles.firstIndex(of: tile) {
//            var t = category.tiles.remove(at: idx)
//            category.tiles.insert(t, at: 0)
//            saveHistory()
//        }
//    }
//    
//    private func moveTileToBottom(_ tile: TileM) {
//        if let idx = category.tiles.firstIndex(of: tile) {
//            let t = category.tiles.remove(at: idx)
//            category.tiles.append(t)
//            saveHistory()
//        }
//    }
//    
//    private func moveTileToArchive(_ tile: TileM) {
//        Task {
//            do {
//                try await viewModel.moveTileThrowing(tile, from: category.id, to: viewModel.archiveCategoryID)
//                saveHistory()
//            } catch { viewModel.lastError = error }
//        }
//    }
//}
