//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct HistoryV: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: HistoryVM
    
    // UI State
    @State private var newTextTiles: [UUID: String] = [:]       /// Store new tile text per category using its `id` as key
    //    @State private var dropTargets: [UUID: Bool] = [:]  /// Drop highlight state per category
    @State private var isOrganizing = false
    @State private var createdCategoryID: UUID?
  
    private var p: ThemePalette { theme.palette(for: .history) }
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .history))    }
    }
    var body: some View {
//        let p = theme.palette(for:.history)
//        
        ZStack(alignment: .bottom) {
            ScrollView {
                Page(top: 4, alignment: .center){
                    header
                    categoriesList(palette: p)
                    Spacer(minLength: 16)
                }
            }
            
            /// Kept outside ScrollView - gives space to GeometryReader
        }
        .safeAreaInset(edge: .bottom) { undoToast }
        .animation(.easeInOut(duration: 0.2), value: viewModel.lastUndoableMove != nil)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(T(isOrganizing ? "Done" : "Organize", .section)) {
                        if isOrganizing { Task { await viewModel.flushPendingSaves() } }    /// When "Done" tapped, force a final write
                        isOrganizing.toggle()
                    }
                    .secondaryActionStyle(screen: .history)
                    
                    Button(T("Add Category", .section)) {
                        if let id = viewModel.addEmptyUserCategory() {
                            createdCategoryID = id
                        }
                    }
                    .disabled(!viewModel.canAddUserCategory())
                    .secondaryActionStyle(screen: .history)
                }
            }
        }
    }
    
    /// Splitting subviews
    @ViewBuilder private var header: some View {
        theme.styledText("Tap a category title to edit and group.", as: .body, in: .history)
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private func categoriesList(palette: ScreenStylePalette) -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach($viewModel.categories, id: \.id) { $categoryItem in   // mutate individual category fields
                /// Disables inputs and editing/ Provides subtle "card" treatment
                /// Derive isArchive from the VM
                let isArchive = categoryItem.id == viewModel.archiveCategoryID
                
                CategorySection(
                    categoryItem: $categoryItem,
                    palette: palette,
                    fontTheme: theme.fontTheme,
                    newTextTiles: $newTextTiles,
                    saveHistory: { viewModel.saveHistory()  },
                    isArchive: isArchive,
                    autoFocus: createdCategoryID == categoryItem.id
                )
            }
        }
    }
    
    @ViewBuilder private var undoToast: some View {
        if let move = viewModel.lastUndoableMove {
            BottomToast {
                HStack {
                    theme.styledText("Moved: \(move.tile.text)", as: .caption, in: .history)
                    Spacer()
                    Button(T("Undo", .action)) {
                        viewModel.undoLastMove()
                    }
                    .secondaryActionStyle(screen: .history)
                }
            }
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            EmptyView()
        }
    }
    
    /// Organizer show as an overlay so it doesn't fight ScrollView dimensions
    @ViewBuilder private var organizerOverlay: some View {
        if isOrganizing {
            GeometryReader { proxy in
                let targetH = min(proxy.size.height * 0.75, 600)    // Use available height, avoid UIScreen.*
                
                VStack(spacing: 12) {
                    theme.styledText("Organize Tiles", as: .section, in: .history)
                        .padding(.top, 12)
                    
                    TileOrganizerWrapper(
                        categories: $viewModel.categories,
                        onMoveTile: { tile, fromID, toID in
                            Task { @MainActor in                /// Using the throwing async core
                                do { try await viewModel.moveTileThrowing(tile, from: fromID, to: toID) }
                                catch { viewModel.lastError = error }
                            }
                        },
                        onReorder: { newTiles, categoryID in
                            viewModel.updateTiles(in: categoryID, to: newTiles)
                            // save (debounced by VM if possible)
                            viewModel.saveHistory()
                        }
                    )
                    .frame(height: targetH)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 3, y: 1)
                    
                    //FIXME: use my buttons
                    Button(T("Done", .section)) { isOrganizing = false }
                        .secondaryActionStyle(screen: .history)
                        .padding(.bottom, 12)
                }
                //FIXME: use my button of this?
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .ignoresSafeArea(.keyboard) // keep organizer steady while keyboard shows
            .zIndex(1)
        }
    }
}

    
    // MARK: extracted CategorySectionRow
    /// Extracted row to simplify type-checking
    private struct CategorySectionRow: View {
        @Binding var categoryItem: CategoriesModel
        let palette: ScreenStylePalette
        let fontTheme: AppFontTheme
        @Binding var newTextTiles: [UUID: String]
        let saveHistory: () -> Void
        let isArchive: Bool
        let autoFocus: Bool
        
        var body: some View {
            let background = isArchive ? Color.secondary.opacity(0.06) : .clear     /// 0.6 is too heavy 0.06 is better
            let stroke = isArchive ? Color.secondary.opacity(0.25) : .clear
            
            CategorySection(
                categoryItem: $categoryItem,
                palette: palette,
                fontTheme: fontTheme,
                newTextTiles: $newTextTiles,
                saveHistory: saveHistory,
                isArchive: isArchive,
                autoFocus: autoFocus
            )
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

                            

                        
//                        Spacer(minLength: 16)
//                    }       //FIXME: IS LazyVStack screwing up the look?
//                    if let error = viewModel.lastError {
//                        ErrorOverlay(error: error) {
//                            viewModel.lastError = nil
//                        }
//                        .zIndex(1)  // Keeps the above the context of it's error
//                    }
//                }
//            }
//            .safeAreaInset(edge: .bottom) {
//                if let move = viewModel.lastUndoableMove {
//                    BottomToast {
//                        HStack {
//                            Text("Moved: \(move.tile.text)").font(.footnote)
//                            Spacer()
//                            Button("Undo") {    viewModel.undoLastMove()    }
//                        }
//                    }
//                    .padding(.horizontal, 16)
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
//                }
//            }
//        }
////        .friendlyAnimatedHelper(viewModel.lastUndoableMove != nil)
//    }
//}

// Mock/ test data prepopulated
#Preview("Populated Preview History") {
    MainActor.assumeIsolated {
        let historyVM = HistoryVM(persistence: PersistenceActor())
        historyVM.ensureGeneralCategory()
        
        if let generalID = historyVM.categories.first?.id {
            historyVM.addToHistory(TileM(text: "Do item"), to: generalID)
            historyVM.addToHistory(TileM(text: "Get other item"), to: generalID)
        }

        return PreviewWrapper {
            HistoryV(viewModel: historyVM)
                .previewTheme()
        }
    }
}
