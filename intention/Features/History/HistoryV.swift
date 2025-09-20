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
    @State private var isOrganizing = false
    @State private var createdCategoryID: UUID?
    @State private var targetCategoryID: UUID?
    //
    @State private var showRenamePicker = false
    @State private var showDeletePicker = false
    @State private var showRenameSheet = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
//        ZStack(alignment: .bottom) {
            ScrollView {
                Page(top: 4, alignment: .center) {
                    T("History", .section)
                    
                    ForEach(viewModel.sortedCategories) { cats in
                        Card {
                            CategoryHeaderRow(category: cats)
                            CategoryTileList(category: cats )
                        }
                    }
                    Spacer(minLength: 16)
                }
                .alert("Delete category?",
                       isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) {
                        if let id = targetCategoryID { _ = viewModel.deleteCategory(id: id) }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Tiles will be moved to Archive.")
                }
                
                // Sheet for renaming (iOS 16-friendly)
                .sheet(isPresented: $showRenameSheet) {
                    NavigationStack {
                        Form {
                            Section("New Name") {
                                TextField("Category name", text: $renameText)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                            }
                        }
                        .navigationTitle("Rename")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showRenameSheet = false }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    if let id = targetCategoryID {
                                        viewModel.renameCategory(id: id, to: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
                                    }
                                    showRenameSheet = false
                                }
                                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            .background()p.background.ignoresSafeArea())
            .tint(p.accent)

            /// Kept outside ScrollView - gives space to GeometryReader
            organizerOverlay

        .safeAreaInset(edge: .bottom, spacing: 10) { VStack(spacing: 10) { undoToast; capToast } }
        .animation(.easeInOut(duration: 0.2), value: viewModel.lastUndoableMove != nil)
        .toolbar { historyToolbar }
        .navigationBarTitleDisplayMode(.inline) // optional, for a tighter header
    }
    
    /// Splitting subviews
    @ViewBuilder
    private var header: some View {
        T("Tasks You Intended to Complete and Did", .body)
            .foregroundStyle(p.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private func categoriesList(p: ScreenStylePalette) -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach($viewModel.categories, id: \.id) { $categoryItem in   // mutate individual category fields
                /// Disables inputs and editing/ Provides subtle "card" treatment
                /// Derive isArchive from the VM
                let isArchive = categoryItem.id == viewModel.archiveCategoryID
                
                CategorySection(
                    categoryItem: $categoryItem,
                    palette: p,
                    fontTheme: theme.fontTheme,
                    newTextTiles: $newTextTiles,
                    saveHistory: { viewModel.saveHistory()  },
                    isArchive: isArchive,
                    autoFocus: createdCategoryID == categoryItem.id
                )
                
                extensionHistoryVM
            }
        }
    }
    
    @ViewBuilder private var undoToast: some View {
        if let move = viewModel.lastUndoableMove {
            BottomToast {
                HStack {
                    T("Moved: \(move.tile.text)", .caption)
                    Spacer()
                    Button( action: { viewModel.undoLastMove() }) {
                        T("Undo", .action)
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
    
    @ViewBuilder private var capToast: some View {
        if viewModel.tileLimitWarning {
            BottomToast {
                HStack {
                    T("Archive capped at 200; oldest items were removed.", .caption)
                    Spacer()
                    Button { viewModel.tileLimitWarning = false } label: { T("OK", .action) }
                        .secondaryActionStyle(screen: .history)
                }
            }
            .padding(.horizontal, 16)
            .task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                viewModel.tileLimitWarning = false
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    /// Organizer show as an overlay so it doesn't fight ScrollView dimensions
    @ViewBuilder private var organizerOverlay: some View {
        if isOrganizing {
            GeometryReader { proxy in
                let targetH = min(proxy.size.height * 0.75, 600)    // Use available height, avoid UIScreen.*
                
                VStack(spacing: 12) {
                    T("Organize Tiles", .section)
                        .padding(.top, 12)
                    
                    TileOrganizerWrapper(
                        categories: $viewModel.categories,
                        onMoveTile: { tile, fromID, toID in
                            Task { @MainActor in                /// Using the throwing async core
                                do { try await viewModel.moveTileThrowing(tile, from: fromID, to: toID) } catch { viewModel.lastError = error }
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
                    
                    Button { viewModel.flushPendingSaves(); withAnimation { isOrganizing = false }} label: {
                        T("Done", .section)
                    }
                    .secondaryActionStyle(screen: .history)
                    .padding(.bottom, 12)
                }
                // FIXME: use my button of this?
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
    
    @ToolbarContentBuilder private var historyToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            
            // Organize / Done toggle
            Button {
                if isOrganizing { viewModel.flushPendingSaves() }
                withAnimation { isOrganizing.toggle() }
            } label: {
                Label {
                    T(isOrganizing ? "Done" : "Organize", .section)
                } icon: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            .secondaryActionStyle(screen: screen)
            
            // More menu
            Menu {
                Button {
                    // If only one user cat, go straight to rename sheet; else pick first
                    if let only = viewModel.userCategoryIDs.only {
                        targetCategoryID = only
                        renameText = viewModel.name(for: only)
                        showRenameSheet = true
                    } else {
                        showRenamePicker = true
                    }
                } label: { T("Rename Category", .section) }
                
                Button {
                    // If only one user cat, confirm delete directly; else choose which
                    if let only = viewModel.userCategoryIDs.only {
                        targetCategoryID = only
                        showDeletePicker = true
                    } else {
                        showDeletePicker = true
                    }
                } label: { T("Delete Category", .section) }
                
                Divider()
                
                Button {
                    if let id = viewModel.addEmptyUserCategory() { createdCategoryID = id }
                } label: { T("Add Category", .section) }
                    .disabled(!viewModel.canAddUserCategory())
                
            } label: {
                Label { T("More", .section) } icon: { Image(systemName: "ellipsis.circle") }
            }
            .secondaryActionStyle(screen: screen)
            
            // Rename picker
            .confirmationDialog("Choose category to rename",
                isPresented: $showRenamePicker,
                titleVisibility: .visible
            ) {
                ForEach(viewModel.userCategoryIDs, id: \.self) { id in
                    let label = viewModel.name(for: id).ifEmpty("Untitled")
                    Button(label) {
                        targetCategoryID = id
                        renameText = viewModel.name(for: id)
                        showRenameSheet = true
                    }
                }
                Button("Cancel", role: .cancel) { }
            }

            // Delete picker (note the role initializer)
            .confirmationDialog("Choose category to delete",
                isPresented: $showDeletePicker,
                titleVisibility: .visible
            ) {
                ForEach(viewModel.userCategoryIDs, id: \.self) { id in
                    let label = viewModel.name(for: id).ifEmpty("Untitled")
                    Button(role: .destructive) {
                        targetCategoryID = id
                        showDeleteConfirm.toggle()
                    } label: {
                        Text(label)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }

        }
    }
}

// UUID helper
extension Array {
    var only: Element? { count == 1 ? first : nil }
}

extension String {
    func ifEmpty(_ replacement: String) -> String { isEmpty ? replacement : self }
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
        let background = isArchive ? palette.surface : .clear
        let stroke     = isArchive ? palette.border  : .clear

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
//            .safeAreaInset(edge: .bottom, spacing: 10) {
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
// }

// Mock/ test data prepopulated
#if DEBUG
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
#endif
