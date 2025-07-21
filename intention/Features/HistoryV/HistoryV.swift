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
    @State private var tileDropHandler = TileDropHandler()
    @State private var dropTargets: [UUID: Bool] = [:]  // Drop highlight state per category
    
    var body: some View {
        
        let palette = theme.palette(for:.history)
        
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("Group by category. Tap a category title to edit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                ForEach($viewModel.categories, id: \.id) { $categoryItem in   // mutate individual category fields
                    
                    CategorySection(
                        categoryItem: $categoryItem,
                        palette: palette,
                        fontTheme: theme.fontTheme,
                        newTextTiles: $newTextTiles,
                        dropTarget: Binding(
                            get: { dropTargets[categoryItem.id] ?? false },
                            set: {  dropTargets[categoryItem.id] = $0 }
                        ),
                        saveHistory: { viewModel.saveHistory()  },
                        tileDropHandler: tileDropHandler,
                        moveTile: { tile, fromID, toID in
                            await viewModel.moveTile(tile, from: fromID, to: toID)
                        }
                    )
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
            .padding(.vertical)
        }
        .padding(.top)
        .background(palette.background.ignoresSafeArea())
    }
//        .foregroundStyle(palette.text)
}


// Mock/ test data prepopulated
#Preview {
    let vm = HistoryVM()
    let theme = ThemeManager()
    let userService = UserService()
    
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    vm.ensureDefaultCategory(userService: userService) // Ensure default category exists
    // Now, safe to unwrap, prepopulate
    if let defaultCategoryID = vm.categories.first?.id {
        vm.addToHistory(TileM(text: "Write report"), to: defaultCategoryID)
        vm.addToHistory(TileM(text: "Prepare slides"), to: defaultCategoryID)
    }
    
    return HistoryV(viewModel: vm)
        .environmentObject(theme)
        .environmentObject(userService)
}
