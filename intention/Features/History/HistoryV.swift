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
    @State var newTextTiles: [UUID: String] = [:]   // Store new tile text per category using its `id` as key
    @State private var dropTargets: [UUID: Bool] = [:]  // Drop highlight state per category
    @State private var isOrganizing = false
    @State private var createdCategoryID: UUID?

    var body: some View {
        
        let palette = theme.palette(for:.history)
        
        ZStack(alignment: .bottom) {
            ScrollView {
                Page {
                    Text("Group by category. Tap a category title to edit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
//                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach($viewModel.categories, id: \.id) { $categoryItem in   // mutate individual category fields
                            /// Disables inputs and editablity/ Provides subtle "card" treatment
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
                            //                        .environmentObject(viewModel)     //FIXME: What is this doing?
                            .background(isArchive ? Color.secondary.opacity(0.06) : .clear)
                            .overlay(RoundedRectangle(cornerRadius: 12) .stroke(isArchive ? Color.secondary.opacity(0.25) : .clear, lineWidth: 1) )
                            .cornerRadius(12)
                            
                            
                            if isOrganizing {
                                TileOrganizerWrapper(
                                    categories: $viewModel.categories,
                                    onMoveTile: { tile, fromID, toID in
                                        Task { @MainActor in        /// Using the throwing async core
                                            do { try await viewModel.moveTileThrowing(tile, from: fromID, to: toID) }
                                            catch { viewModel.lastError = error }
                                        }
                                    },
                                    onReorder: { newTiles, categoryID in
                                        viewModel.updateTiles(in: categoryID, to: newTiles)
                                        viewModel.saveHistory()
                                    }
                                )
                                .frame(height: UIScreen.main.bounds.height * 0.75)
                            }
                        }
                        Spacer(minLength: 16)
//                    }       //FIXME: IS LazyVStack screwing up the look?
                    if let error = viewModel.lastError {
                        ErrorOverlay(error: error) {
                            viewModel.lastError = nil
                        }
                        .zIndex(1)  // Keeps the above the context of it's error
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let move = viewModel.lastUndoableMove {
                    BottomToast {
                        HStack {
                            Text("Moved: \(move.tile.text)").font(.footnote)
                            Spacer()
                            Button("Undo") {    viewModel.undoLastMove()    }
                            //FIXME: What is this doing?
                                                    .padding()
                                                    .background(.ultraThinMaterial)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .padding(.horizontal)
                                                    .padding(.bottom, 44)       /// Tab bar clearance?
                                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                                    .zIndex(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .friendlyAnimatedHelper(viewModel.lastUndoableMove != nil)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isOrganizing ? "Done" : "Organize") {isOrganizing.toggle() }
                
                Button("Add Category") {
                    if let id = viewModel.addEmptyUserCategory() {
                        createdCategoryID = id
                    }
                }
                .disabled(!viewModel.canAddUserCategory())
            }
        }
    }
}

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
