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
    @State private var showOrganizerOverlay = false
    @State private var showErrorOverlay = false
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
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
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
                            }
                        )
                        .id(category.id)
                        
                        // -- category separator --
                        Rectangle()
                            .fill(colorBorder)
                            .frame(height: 1)
                            .padding(.vertical, 4)
                    }
                }
            }
            
            // Toasts
            VStack(spacing: 8) {
                if let move = viewModel.lastUndoableMove {
                    HStack {
                        //                        Text("\(move.tile.text) moved").font(.footnote)
                        //                        Spacer()
                        Button {viewModel.undoLastMove()} label: { T("Undo?", .action) }.primaryActionStyle(screen: screen)
                    }
                    .padding(.horizontal, 12)           // Card instead?
                    .padding(.vertical, 10)             // Card instead?
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if viewModel.tileLimitWarning {
                    T("Archive capped at 200; oldest items were removed.", .tile)
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
        .background(p.background)
        .opacity(isOrganizing ? 0.98 : 1.0) // so history bg wins against organizerOverlay
        .zIndex(0)      // so the history background wins against organizerOverlay
        .tint(p.accent)
        // nav bar background reacts to edit mode
        .toolbarBackground(isOrganizing ? p.background.opacity(0.92) : .clear, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        
        .animation(.easeInOut(duration: 0.2), value: viewModel.lastUndoableMove != nil)
        .toolbar { historyToolbar }
        .environmentObject(theme)
        //        /// [.medium] is half-screen, .visible affordance
        //        .sheet(isPresented: $showRenameSheet) {
        //            renameSheet
        //                .presentationDetents([.medium])
        //                .presentationDragIndicator(.visible)
        //        }
        .fullScreenCover(isPresented: $showRenameSheet) {
            RenamingSheetChrome(onClose: {
                showRenameSheet = false
            }) {
                let currentName = {
                    guard let id = targetCategoryID else { return "" }
                    return viewModel.name(for: id)
                }()
                
                NavigationStack {
                    RenameCategoryV(
                        originalName: currentName, text: $renameText, onCancel: { showRenameSheet = false }, onSave: {
                            let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let id = targetCategoryID, !trimmed.isEmpty {
                                viewModel.renameCategory(id: id, to: trimmed)
                            }
                            showRenameSheet = false
                        }
                    )
                    .navigationBarHidden(true)
                    .environmentObject(theme)
                }
                
            }
            .interactiveDismissDisabled(false)
        }
        .alert("Delete category?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let id = targetCategoryID {
                    Task { _ = viewModel.deleteCategory(id: id) }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Tiles will be moved to Archive.") }
        
            .fullScreenCover(isPresented: $isOrganizing
                             //                             //FIXME: - Does this =work without onDismiss?
                             //                             onDismiss: { viewModel.flushPendingSaves() }
            ) {
                OrganizerOverlayChrome(onClose: {
                    //FIXME: - Does this CLOSE AND save without flushPendingSaves?
                    //                    viewModel.flushPendingSaves()
                    isOrganizing = false
                }) {
                    OrganizerOverlayScreen(
                        categories: $viewModel.categories,
                        onMoveTile: { tile, sourceID, destinationID in
                            Task { @MainActor in
                                do { try await viewModel.moveTileThrowing(tile, fromCategory: sourceID, toCategory: destinationID) }
                                catch { viewModel.lastError = error }
                            }
                        },
                        onReorder: { newTiles, categoryID in
                            // reorderTiles already applies caps AND persists, saveHistory() isn't needed
                            viewModel.reorderTiles(newTiles, in: categoryID)
                        },
                        onDone: {
                            // close path X/drag like RecalibrationChrome
                            //FIXME: - Does this CLOSE AND save without flushPendingSaves?
                            // viewModel.flushPendingSaves()
                            isOrganizing = false
                        }
                    )
                    .environmentObject(theme)
                }
                // Chrome owns gesture/X dismissal
                .interactiveDismissDisabled(true)
            }
        // HistoryV: the flush in .task(id: isOrganizing) when it becomes false,
        // - happens ONCE here, when the cover closes
            .task(id: isOrganizing) {
                // On leaving organize mode, force-flush pending saves.
                if !isOrganizing { viewModel.flushPendingSaves() }
            }
            .overlay {
                if let error = viewModel.lastError {
                    ErrorOverlay(error: error) { viewModel.setError(nil) }
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1)
                        .allowsHitTesting(true)     // opt-in to hits only when visible
                }
            }
        Spacer(minLength: 0)
    }
    
    
    //    @ToolbarContentBuilder private var historyToolbar: some ToolbarContent {
    //        ToolbarItemGroup(placement: .topBarTrailing) {
    @ToolbarContentBuilder
    private var historyToolbar: some ToolbarContent {
        // Primary edit/done toggle - keep as trailing item
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                if isOrganizing { viewModel.flushPendingSaves() }
                withAnimation { isOrganizing.toggle() }
            } label: {
                Label(isOrganizing ? "Done" : "Edit", systemImage: "arrow.up.and.down.text.designator"
                ).foregroundStyle(p.primary)
            }
        }
        
        // Menu {
        // Title menu = category management + quick actions
        ToolbarItem(placement: .principal) {
            List {}
            T("History", .header)
                .toolbarTitleMenu {
                    // --- Organize toggle (mirrors the top-right button) ---
                    Button(isOrganizing ? "Done Organizing" : "Organize") {
                        if isOrganizing { viewModel.flushPendingSaves() }
                        withAnimation { isOrganizing.toggle() }
                    }
                    
                    Divider()
                    
                    // --- Add category (guarded by VM cap) ---
                    //                        Button("Add Category") {
                    Button( action: {
                        if let id = viewModel.addEmptyUserCategory() { createdCategoryID = id
                        } else {
                            debugPrint("Add Not Possible")
                        }
                    }, label: {
                        Image(systemName: "plus")
                        T("Add Category", .action)
                    })
                    .disabled(!viewModel.canAddUserCategory())
                    
                    // --- Rename category (picker if multiple) ---
                    //                        Button("Rename Category") {
                    Button( action: {
                        if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
                            targetCategoryID = only
                            renameText = viewModel.name(for: only)
                            showRenameSheet = true
                        } else {
                            showRenamePicker = true
                        }
                    }, label: {
                        Image(systemName: "pen")
                        T("Rename Category", .action)
                    })
                    
                    // --- Delete category (moves tiles to Archive by spec) ---
                    // Button("Delete Category", role: .destructive) {
                    Button(role: .destructive, action: {
                        if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
                            targetCategoryID = only
                            showDeleteConfirm = true
                        } else {
                            showDeletePicker = true
                        }
                    },label: {
                        Image(systemName: "trash")
                        T("Delete Category", .action)
                    })
                    
                    Divider()
                    
                    // --- Quick Archive: archive latest General tile ---
                    Button(action: {
                        Task { @MainActor in
                            await viewModel.archiveMostRecentFromGeneral()
                        }}) {
                            Image(systemName: "arrow.up.circle")
                            T("Archive Most Recent From General", .action)
                        }
                        .disabled(!viewModel.hasAnyGeneralTiles)
                }
            //
            //                .background(colorBorder)
            //                .clipShape(Capsule())
            //                .foregroundStyle(colorDanger)
            //                .imageScale(.small).font(.headline).controlSize(.large).tint(.red)
            
            //                Button("Rename") {
            //                    if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
            //                        targetCategoryID = only
            //                        renameText = viewModel.name(for: only)
            //                        showRenameSheet = true
            //                    } else {
            //                        showRenamePicker = true
            //                    }
            //                }
            
            //                Button(role: .destructive, action: {
            //                    if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
            //                        targetCategoryID = only
            //                        showDeleteConfirm = true
            //                    }
            //                    else {
            //                        showDeletePicker = true
            //                    }
            //                },label: {
            //                    Image(systemName: "trash")
            //                })
            //                .background(colorBorder)
            //                .clipShape(Capsule())
            //                .foregroundStyle(colorDanger)
            //                .imageScale(.small).font(.headline).controlSize(.large).tint(.red)
            //
            Button( action: {
                if let id = viewModel.addEmptyUserCategory() {
                    createdCategoryID = id
                } else {
                    debugPrint("Add Not Possible")
                }
            }, label: {
                Image("plus")
            })
            .disabled(!viewModel.canAddUserCategory())
            .background(colorBorder)
            .clipShape(Capsule())
            .imageScale(.small).font(.headline).controlSize(.large).tint(p.accent)
            
            //                Button("Delete", role: .destructive) {
            //                    if let only = viewModel.userCategoryIDs.first, viewModel.userCategoryIDs.count == 1 {
            //                        targetCategoryID = only
            //                        showDeleteConfirm = true
            //                    } else {
            //                        showDeletePicker = true
            //                    }
            //                }
            //                    Image(systemName: "trash").imageScale(.small).font(.headline).controlSize(.large)
            
            
            //                Button("Add") {
            //                    if let id = viewModel.addEmptyUserCategory() {
            //                        createdCategoryID = id
            //                    }
            //                } label: {
            //                    Image(systemName: "plus").imageScale(.small).font(.headline).controlSize(.large)
            //                }
            //                .disabled(!viewModel.canAddUserCategory())
        }
        //            } label: {
        //                Image(systemName: "line.3.horizontal").imageScale(.small).font(.headline).controlSize(.large).tint(p.accent)
        //            }
        //            .buttonStyle(.plain)
    }
}

// UUID helper
extension Array {
    var only: Element? { count == 1 ? first : nil }
}

// MARK: - Category Card (local) Header  Tile List
///composes CategoryHeaderRow  CategoryTileList with the rounded card chrome. Keeping it private avoids scattering styling across files and keeps the view tree simple
private struct CategoryCard: View {
    @Binding var category: CategoriesModel
    let isArchive: Bool
    var onRename: (UUID) -> Void
    
    @EnvironmentObject private var viewModel: HistoryVM
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CategoryHeaderRow(
                title: isArchive ? "Archive" : category.persistedInput.ifEmpty("Untitled"),
                count: category.tiles.count,
                isArchive: isArchive,
                allowEdit: !isArchive && category.id != viewModel.generalCategoryID,
                onRename: {  onRename(category.id) },       // NOTE: CategoryHeaderRow expects () -> Void, adapt by calling the closure with category.id
            )
            
            CategoryTileList(category: $category, isArchive: isArchive)
                .padding(.vertical, 12)
                .environmentObject(viewModel)
                .environmentObject(theme)
        }
    }
    
}


// MARK: - RenameCategoryV (local, a form)
private struct RenameCategoryV: View {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName = .history
    
    var originalName: String
    @Binding var text: String
    var onCancel: () -> Void
    var onSave: () -> Void
    
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    
    var body: some View {
        VStack(spacing: 16) {
            // Handle area already provided by Chrome; minimal UI
            VStack(alignment: .leading, spacing: 12) {
                Text("Rename Category")
                    .font(theme.fontTheme.toFont(.title2))
                    .fontWeight(.semibold)
                    .foregroundStyle(p.text)
                
                TextField("Category name", text: $text)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                
                HStack(spacing: 12) {
                    Button(action: onCancel) { Text("Cancel") }
                        .secondaryActionStyle(screen: screen)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    
                    Button(action: onSave) { Text("Save") }
                        .primaryActionStyle(screen: screen)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  text.trimmingCharacters(in: .whitespacesAndNewlines) == originalName)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .background(Color.clear) // Chrome provides bg
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
            historyVM.addToHistory(TileM(text: "Color background from gray-ish to history Tan"), to: generalID)
            historyVM.addToHistory(TileM(text: "Define Dividers as the light tan"), to: generalID)
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
            h.addToHistory(TileM(text: "Refactor the organizerOverlay"), to: userID)
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
