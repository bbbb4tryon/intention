//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct HistoryV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var userService: UserService
    
    @ObservedObject var viewModel: HistoryVM
    @State var newTextTiles: [UUID: String] = [:]   // Store new tile text per category using its `id` as key
    @State private var dropTargets: [UUID: Bool] = [:]  // Drop highlight state per category
    @State private var isOrganizing = false
    
    var body: some View {
        
        let palette = theme.palette(for:.history)
        
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                
                Text("Group by category. Tap a category title to edit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                ForEach($viewModel.categories, id: \.id) { $categoryItem in   // mutate individual category fields
                    /// Disables inputs and editablity
                    let isArchive = categoryItem.id == userService.archiveCategoryID
                    Label(isArchive ? "Archive" : categoryItem.persistedInput,
                          systemImage: isArchive ? "lock.fill" : "folder")
                    .foregroundStyle(isArchive ? .secondary : palette.text)
                    
                    CategorySection(
                        categoryItem: $categoryItem,
                        palette: palette,
                        fontTheme: theme.fontTheme,
                        newTextTiles: $newTextTiles,
                        saveHistory: { viewModel.saveHistory()  },
                        isArchive: isArchive
                    )
                    
                    
                    if isOrganizing {
                        TileOrganizerWrapper(
                            categories: $viewModel.categories,
                            onMoveTile: { tile, fromID, toID in
                                Task {
                                    await viewModel.moveTile(tile, from: fromID, to: toID)
                                }
                            },
                            onReorder: { newTiles, categoryID in
                                viewModel.updateTiles(in: categoryID, to: newTiles)
                                viewModel.saveHistory()
                            }
                        )
                        .frame(height: UIScreen.main.bounds.height * 0.75) // whatever layout you prefer
                    }
                    
                }
                Spacer()
                if let move = viewModel.lastUndoableMove {
                    VStack {
                        Spacer()
                        HStack {
                            Text("Moved \"\(move.tile.text)\"")
                                .font(.footnote)
                                .foregroundStyle(.white)
                            Spacer()
                            Button("Undo") {
                                viewModel.undoLastMove()
                            }
                            .foregroundStyle(.blue)
                        }
                        .padding()
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(10)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: viewModel.lastUndoableMove != nil)
                }
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button(isOrganizing ? "Done" : "Organize") {isOrganizing.toggle() }
            }}
            if let error = viewModel.lastError {
                ErrorOverlay(error: error) {
                    viewModel.lastError = nil
                }
                .zIndex(1)  // Keeps the above the context of it's error
            }
        }
        //        .foregroundStyle(palette.text)
    }
}


// Mock/ test data prepopulated
#Preview("Populated History") {
    MainActor.assumeIsolated {
        let userService = PreviewMocks.userService
        let historyVM = HistoryVM(userService: userService)
        historyVM.ensureDefaultCategory(userService: userService)
        if let defaultID = historyVM.categories.first?.id {
            historyVM.addToHistory(TileM(text: "Do taxes"), to: defaultID)
            historyVM.addToHistory(TileM(text: "Buy groceries"), to: defaultID)
        }

        return PreviewWrapper {
            HistoryV(viewModel: historyVM)
                .environmentObject(userService)
        }
    }
}
