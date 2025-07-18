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
    
    var body: some View {
        
        let palette = theme.palette(for:.history)
        
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("Group by category. Tap a category title to edit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                ForEach($viewModel.categories, id: \.id) { $categoryItem in   // mutate individual category fields
                    VStack(alignment: .leading, spacing: 8) {
                        // Editable category name
                        CategoryHeaderRow(
                            categoryItem: $categoryItem,
                            palette: palette,
                            fontTheme: theme.fontTheme,
                            newTextTiles: $newTextTiles
                        )
                        
                        CategoryTileList(
                            categoryItem: $categoryItem,
                            palette: palette,
                            fontTheme: theme.fontTheme,
                            saveHistory: { viewModel.saveHistory()  }
                        )
                    }

                        //                        Spacer()
                        
                     
                    .padding(.bottom, 12)
                }
                .padding(.vertical)
            }
            .padding(.top)
        }
        .background(palette.background.ignoresSafeArea())
        .foregroundStyle(palette.text)
    }
}


//                                }
//                                .frame(height: CGFloat(categoryItem.tiles.count) * 60) // Adjust height if needed
//                                .listStyle(PlainListStyle())
//                                .scrollDisabled(true)               // Disables inner scrolling - avoids nested scrolling
//                            }
//                        }
//                            .padding(.bottom, 12)
//                    }
//                }
//                .padding(.vertical)
//                //            .font(theme.fontTheme.toFont(.title3))    // default body styling
//            }
//            .background(palette.background.ignoresSafeArea())
//            .foregroundStyle(palette.text)
//    }
//}

// Mock/ test data prepopulated
#Preview {
    let vm = HistoryVM()
    let theme = ThemeManager()
    let userService = UserService()
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    
    // Ensure default category exists
    vm.ensureDefaultCategory(userService: userService)
    // Now, safe to unwrap, prepopulate
    if let defaultCategoryID = vm.categories.first?.id {
        vm.addToHistory(TileM(text: "Write report"), to: defaultCategoryID)
        vm.addToHistory(TileM(text: "Prepare slides"), to: defaultCategoryID)
    }
    
    return HistoryV(viewModel: vm)
        .environmentObject(theme)
        .environmentObject(userService)
}
