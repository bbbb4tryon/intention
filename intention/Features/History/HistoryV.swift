//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
/// content-management screen with an explicit Edit/Done mode
struct HistoryV: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: HistoryVM
    @Environment(\.editMode) private var editMode
    
    // UI State
    //    @State private var newTextTiles: [UUID: String] = [:]       /// Store new tile text per category using its `id` as key
    @State private var isOrganizing = false
    @State private var createdCategoryID: UUID?
    @State private var targetCategoryID: UUID?
    @State private var showRenamePicker = false
    @State private var showDeletePicker = false
    @State private var showRenameSheet = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    @State private var isBusy = false
    
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        ScrollView {
            Page(top: 6, alignment: .center) {
                
                LazyVStack(alignment: .leading, spacing: 8) {
                    // $Bindings are so rows can edit categories
                    ForEach($viewModel.categories) { $category in
                        CategoryCard(
                            category: $category,
                            isArchive: category.id == viewModel.archiveCategoryID,
                            onRename: { id in
                                targetCategoryID = id
                                renameText = viewModel.name(for: id)
                                showRenameSheet = true
                            },
                            onDelete: { id in
                                targetCategoryID = id
                                showDeleteConfirm = true
                            }
                        )
                        .id(category.id)
                        .padding(.horizontal, 16)
                        .environmentObject(theme)
                    }
                }
                .padding(.vertical, 12)
            }
            // Toasts
            VStack(spacing: 8) {
                if let move = viewModel.lastUndoableMove {
                    HStack {
                        Text("\(move.tile.text) moved").font(.footnote)
                        Spacer()
                        Button {viewModel.undoLastMove() } label: { T("Undo", .action) }.primaryActionStyle(screen: screen)
                    }
                    .padding(.horizontal, 12)           // Card instead?
                    .padding(.vertical, 10)             // Card instead?
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if viewModel.tileLimitWarning {
                    Text("Archive capped at 200; oldest items were removed.")
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await MainActor.run { viewModel.tileLimitWarning = false }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        .animation(.easeInOut(duration: 0.2), value: viewModel.lastUndoableMove != nil)
        .toolbar { historyToolbar }.environmentObject(theme)
        /// [.medium] is half-screen, .visible affordance
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete category?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let id = targetCategoryID {
                    Task { _ = viewModel.deleteCategory(id: id) }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Tiles will be moved to Archive.") }
        
        
            .fullScreenCover(isPresented: $isOrganizing,
                             onDismiss: { viewModel.flushPendingSaves() }) {
                OrganizerOverlayScreen(
                    categories: $viewModel.categories,
                    onMoveTile: { tile, fromID, toID in
                        Task { @MainActor in
                            do { try await viewModel.moveTileThrowing(tile, from: fromID, to: toID) }
                            catch { viewModel.lastError = error }
                        }
                    },
                    onReorder: { newTiles, categoryID in
                        viewModel.updateTiles(in: categoryID, to: newTiles)
                        viewModel.saveHistory()
                    },
                    onDone: {
                        viewModel.flushPendingSaves()
                        isOrganizing = false
                    }
                )
                .environmentObject(theme)
                // Match Membership background exactly (Default = systemGroupedBackground)
                .background(theme.palette(for: .membership).background.ignoresSafeArea())
                // If you want to block swipe-down dismissal, uncomment:
                // .interactiveDismissDisabled(true)
            }
                             .task(id: isOrganizing) {
                                 // On leaving organize mode, force-flush pending saves.
                                 if !isOrganizing { viewModel.flushPendingSaves() }
                             }
    }
    
    //    @ToolbarContentBuilder private var historyToolbar: some ToolbarContent {
    //        ToolbarItemGroup(placement: .topBarTrailing) {
    @ToolbarContentBuilder
    private var historyToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                if isOrganizing { viewModel.flushPendingSaves() }
                withAnimation { isOrganizing.toggle() }
            } label: {
                Label(
                    isOrganizing ? "Done" : "Edit", systemImage: "arrow.up.arrow.down"
                ).foregroundStyle(p.primary)
            }
            
            Menu {
                Button("Rename Category") {
                    if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
                        targetCategoryID = only
                        renameText = viewModel.name(for: only)
                        showRenameSheet = true
                    } else {
                        showRenamePicker = true
                    }
                }
                
                Button("Delete Category", role: .destructive) {
                    if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
                        targetCategoryID = only
                        showDeleteConfirm = true
                    } else {
                        showDeletePicker = true
                    }
                }
                
                Divider()
                
                Button("Add Category") {
                    if let id = viewModel.addEmptyUserCategory() {
                        createdCategoryID = id
                    }
                }
                .disabled(!viewModel.canAddUserCategory())
            } label: {
                Image(systemName: "ellipsis.circle").foregroundStyle(p.primary)
            }
        }
    }
    
    
    @ViewBuilder private var renameSheet: some View {
        NavigationStack {
            Form {
                Section("New Name") {
                    TextField("Category name", text: $renameText)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    Button { Task { viewModel.canAddUserCategory() } } label: { T("Rename Category", .action) }
                        .primaryActionStyle(screen: screen)
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
// UUID helper
extension Array {
    var only: Element? { count == 1 ? first : nil }
}

// MARK: - Category Card (private) = Header + Tile List
///composes CategoryHeaderRow + CategoryTileList with the rounded card chrome. Keeping it private avoids scattering styling across files and keeps the view tree simple
private struct CategoryCard: View {
    @Binding var category: CategoriesModel
    let isArchive: Bool
    var onRename: (UUID) -> Void
    var onDelete: (UUID) -> Void
    @EnvironmentObject private var viewModel: HistoryVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CategoryHeaderRow(
                title: isArchive ? "Archive" : category.persistedInput.ifEmpty("Untitled"),
                count: category.tiles.count,
                isArchive: isArchive,
                allowEdit: !isArchive && category.id != viewModel.generalCategoryID,
                onRename: { onRename(category.id) },
                onDelete:  { onDelete(category.id) }
            )
            
            CategoryTileList(category: $category, isArchive: isArchive)
                .environmentObject(viewModel)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - OrganizerOverlayScreen
private struct OrganizerOverlayScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @Binding var categories: [CategoriesModel]
    var onMoveTile: (TileM, UUID, UUID) -> Void
    var onReorder: (_ newTiles: [TileM], _ categoryID: UUID) -> Void
    var onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                TileOrganizerWrapper(
                    categories: $categories,
                    onMoveTile: onMoveTile,
                    onReorder: onReorder
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 3, y: 1)
                .padding(16)
            }
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDone() }.font(.body).controlSize(.large)

                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button{ dismiss() }
                    label: { Image(systemName: "xmark").imageScale(.small).font(.body).controlSize(.large) }.buttonStyle(.plain).accessibilityLabel("Close")
                }
            }
        }
        // If you *always* want systemGroupedBackground regardless of theme:
        // .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// UUID helper
private extension String {
    func ifEmpty(_ replacement: String) -> String { isEmpty ? replacement : self }
}

#if DEBUG
extension HistoryV {
    init(
        viewModel: HistoryVM,
        _preview_isOrganizing: Bool = false,
        _preview_showRenameSheet: Bool = false,
        _preview_targetCategoryID: UUID? = nil,
        _preview_renameText: String = ""
    ) {
        self.viewModel = viewModel
        _isOrganizing    = State(initialValue: _preview_isOrganizing)
        _showRenameSheet = State(initialValue: _preview_showRenameSheet)
        _targetCategoryID = State(initialValue: _preview_targetCategoryID)
        _renameText      = State(initialValue: _preview_renameText)
    }
}
#endif


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

#if DEBUG
#Preview("History — Organizer Overlay") {
    MainActor.assumeIsolated {
        // Build a self-contained HistoryVM with some tiles
        let h = HistoryVM(persistence: PersistenceActor())
        h.ensureGeneralCategory()
        h.ensureArchiveCategory()
        
        if let userID = h.addEmptyUserCategory() {
            h.renameCategory(id: userID, to: "Projects")
            h.addToHistory(TileM(text: "Refactor overlay"), to: userID)
            h.addToHistory(TileM(text: "Add accessibility"), to: userID)
            h.addToHistory(TileM(text: "Debug accessibility"), to: userID)
            h.addToHistory(TileM(text: "Ship v1"), to: userID)
            h.addToHistory(TileM(text: "Prep screenshots"), to: userID)
        }
        
        return PreviewWrapper {
            // Force organizer overlay ON for preview
            HistoryV(viewModel: h, _preview_isOrganizing: true)
        }
    }
}
#endif
