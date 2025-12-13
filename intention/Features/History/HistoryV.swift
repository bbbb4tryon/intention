//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

/// content-management screen
/// swipes live in CategoryTileList
struct HistoryV: View {
    @EnvironmentObject var theme: ThemeManager
    
    @ObservedObject var viewModel: HistoryVM
    
    @Environment(\.dismiss) private var dismiss

    
    // UI State
    @State private var createdCategoryID: UUID?
    @State private var targetCategoryID: UUID?
    @State private var showRenamePicker = false
    @State private var showDeletePicker = false
    @State private var showRenameSheet = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    @State private var isBusy = false
    
    /// Theme hooks
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let dividerRects = Color(red: 0.878, green: 0.847, blue: 0.796)
    
    // MARK: - Computed helpers
    
    private var canAddCategory: Bool {
        viewModel.canAddUserCategory()
    }
    
    private var hasGeneralTiles: Bool {
        viewModel.hasAnyGeneralTiles
    }
    
    private var historyTitleText: Text {
        T("History", .header)
    }
    
    private func finalizeHistoryIfNeededOnDisappear() {
        viewModel.commitPendingUndoIfAny()
        viewModel.flushPendingSaves()
    }
    
    // MARK: - Body
    
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
                        separator
                        //                        Rectangle()
                        //                            .fill(colorBorder)
                        //                            .frame(height: 1)
                        //                            .padding(.vertical, 4)
                        
                    }
                }
            }
            
            // Toasts
            HistoryToasts()
                .padding(.bottom, 8)
        }
        .background(p.background)
        .tint(p.accent)
        .toolbarBackground(.visible, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: viewModel.lastUndoableMove != nil)
        .toolbar { historyToolbar }
        .environmentObject(theme)
        .environmentObject(viewModel)
        .overlay {
            if let error = viewModel.lastError {
                ErrorOverlay(error: error) { viewModel.setError(nil) }
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1)
                    .allowsHitTesting(true)     // opt-in to hits only when visible
            }
        }
        .onDisappear {
            finalizeHistoryIfNeededOnDisappear()
        }
        .sheet(isPresented: $showRenameSheet) {
            renameCategorySheet
        }
        
        .alert("Delete category?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let id = targetCategoryID {
                    Task { _ = viewModel.deleteCategory(id: id) }
                } else {
                    debugPrint("[HistoryV] Delete confirm fired but targetCategoryID is nil")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            T("Tiles will be moved to Archive.", .tile)
        }
    }

    // MARK: - Subviews
    private var separator: some View {
        Rectangle()
            .fill(dividerRects)
            .frame(height: 1)
            .padding(.leading, 6)
            .padding(.trailing, 6)
            .padding(.top, 6)
    }
    
    
    // MARK: - Rename Sheet
    private var renameCategorySheet: some View {
        RenamingSheetChrome(onClose: {
            showRenameSheet = false
        }) {
            let currentName: String = {
                guard let id = targetCategoryID else { return "" }
                return viewModel.name(for: id)
            }()
            
            NavigationStack {
                RenameCategoryV(
                    originalName: currentName,
                    text: $renameText,
                    onCancel: { showRenameSheet = false },
                    onSave: {
                        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let id = targetCategoryID, !trimmed.isEmpty {
                            viewModel.renameCategory(id: id, to: trimmed)
                        } else if trimmed.isEmpty {
                            debugPrint("[HistoryV] Rename attempted with empty string; ignoring")
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
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var historyToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            historyTitleMenu
        }
    }
    
    private var historyTitleMenu: some View {
        historyTitleText
            .toolbarTitleMenu {
                addCategoryToolbarButton
                renameCategoryToolbarButton
                deleteCategoryToolbarButton
                
                Divider()
                
                archiveMostRecentToolbarButton
            }
    }
    
    // MARK: Toolbar button blocks (Image + T pattern)
    private var addCategoryToolbarButton: some View {
        Button(action: {
            if let id = viewModel.addEmptyUserCategory() {
                createdCategoryID = id
            } else {
                debugPrint("[HistoryV] Add category not possible (cap hit)")
            }
        }) {
            HStack {
                Image(systemName: "plus")
                T("Add Category", .action)
            }
        }
        .disabled(!canAddCategory)
    }
    
    private var renameCategoryToolbarButton: some View {
        Button(action: {
            if let only = viewModel.userCategoryIDs.only {
                targetCategoryID = only
                renameText = viewModel.name(for: only)
                showRenameSheet = true
            } else {
                showRenamePicker = true
            }
        }) {
            HStack {
                Image(systemName: "pencil")
                T("Rename Category", .action)
            }
        }
    }
    
    private var deleteCategoryToolbarButton: some View {
        Button(role: .destructive, action: {
            if let only = viewModel.userCategoryIDs.only {
                targetCategoryID = only
                showDeleteConfirm = true
            } else {
                showDeletePicker = true
            }
        }) {
            HStack {
                Image(systemName: "trash")
                T("Delete Category", .action)
            }
        }
    }
    
    private var archiveMostRecentToolbarButton: some View {
        Button(action: {
            Task { await viewModel.archiveMostRecentFromGeneral() }
        }) {
            HStack {
                Image(systemName: "arrow.up.circle")
                T("Archive Most Recent From General", .action)
            }
        }
        .disabled(!hasGeneralTiles)
    }
}


//    //    @ToolbarContentBuilder private var historyToolbar: some ToolbarContent {
//    //        ToolbarItemGroup(placement: .topBarTrailing) {
//    @ToolbarContentBuilder
//    private var historyToolbar: some ToolbarContent {
//        // Primary edit/done toggle - keep as trailing item
//        ToolbarItemGroup(placement: .principal) {
//            T("History", .header)
//                .toolbarTitleMenu {
//                    // Add category - guarded by VM cap
//                    Button {
//                        if let id = viewModel.addEmptyUserCategory() { createdCategoryID = id } else {
//                            debugPrint("Add Not Possible")
//                        }
//                    } label: {
//                        Image(systemName: "plus"); T("Add Category", .action)
//                    }
//                    .disabled(!viewModel.canAddUserCategory())
//                    .background(colorBorder)
//                    //                    .imageScale(.small).font(.headline).controlSize(.large).tint(p.accent)
//
//                    // Rename (single category fast path, else show picker in your UI)
//                    Button {
//                        if let only = viewModel.userCategoryIDs.only {
//                            targetCategoryID = only
//                            renameText = viewModel.name(for: only)
//                            showRenameSheet = true
//                        } else {
//                            showRenamePicker = true
//                        }
//                    } label: {
//                        Image(systemName: "pencil"); T("Rename Category", .action)
//                    }
//
//                    // Delete (moves tiles to Archive)
//                    Button(role: .destructive) {
//                        if let only = viewModel.userCategoryIDs.only {
//                            targetCategoryID = only
//                            showDeleteConfirm = true
//                        } else {
//                            showDeletePicker = true
//                        }
//                    } label: {
//                        Image(systemName: "trash"); T("Delete Category", .action)
//                    }
//
//                    Divider()
//
//                    // Quick archive from General
//                    Button {
//                        Task { await viewModel.archiveMostRecentFromGeneral() }
//                    } label: {
//                        Image(systemName: "arrow.up.circle"); T("Archive Most Recent From General", .action)
//                    }
//                    .disabled(!viewModel.hasAnyGeneralTiles)
//                }
//        }
//    }
//}

// UUID helper
extension Array {
    var only: Element? { count == 1 ? first : nil }
}

// MARK: - Category Card (local)
// Creates rounded card chrome around CategoryHeaderRow and CategoryTileList
private struct CategoryCard: View {
    @EnvironmentObject private var viewModel: HistoryVM
    @EnvironmentObject private var theme: ThemeManager
    

    @Binding var category: CategoriesModel
    let isArchive: Bool
    var onRename: (UUID) -> Void
    
    /// Theme hooks
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CategoryHeaderRow(
                title: isArchive ? "Archive" : category.persistedInput.ifEmpty("Untitled"),
                count: category.tiles.count,
                isArchive: isArchive,
                allowEdit: !isArchive && category.id != viewModel.generalCategoryID,
                onRename: {  onRename(category.id) },       // NOTE: CategoryHeaderRow expects () -> Void, adapt by calling the closure with category.id
            )
            CategoryTileList(
                category: $category,
                isArchive: isArchive
            )
            .padding(.vertical, 12)
            .environmentObject(viewModel)
            .environmentObject(theme)
        }
        .padding(.horizontal, 6)
    }
}


// MARK: - RenameCategoryV
// a form - it is shown in RenamingSheetChrome
private struct RenameCategoryV: View {
    @EnvironmentObject var theme: ThemeManager
    
    var originalName: String
    @Binding var text: String
    var onCancel: () -> Void
    var onSave: () -> Void
    
    /// Theme hooks
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        VStack(spacing: 16) {
            // Handle area already provided by Chrome; minimal UI
            VStack(alignment: .leading, spacing: 12) {
                T("Rename Category", .header)
                
                TextField("Category name", text: $text)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        HStack {
                            Image(systemName: "xmark")
                            T("Cancel", .action)
                        }
                    }
                    .secondaryActionStyle(screen: screen)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark")
                            T("Save", .action)
                        }
                    }
                    .primaryActionStyle(screen: screen)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        text.trimmingCharacters(in: .whitespacesAndNewlines) == originalName
                    )
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

// MARK: - HistoryToasts
/// Extracted toast stack so HistoryV reads as: list → toasts → overlays.
private struct HistoryToasts: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var viewModel: HistoryVM
    
    /// Theme Hooks
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    private var showsUndoToast: Bool {
        viewModel.pendingUndoMove != nil
    }
    
    private var showsArchiveCapToast: Bool {
        viewModel.tileLimitWarning
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if showsUndoToast {
                undoToast
            }
            
            if showsArchiveCapToast {
                archiveCapToast
            }
        }
    }
    
    // MARK: - Individual toasts
    private var undoToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward")
                .imageScale(.medium)
                .foregroundStyle(p.text)
            
            T("Moved.", .secondary)
            
            Spacer()
            
            Button(action: {
                viewModel.undoPendingMoveIfPossible()
            }) {
                HStack {
                    Image(systemName: "arrow.uturn.backward.circle")
                    T("Undo", .action)
                }
            }
            .primaryActionStyle(screen: screen)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var archiveCapToast: some View {
        T("Archive capped at 200; oldest items were removed.", .tile)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .task {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run { viewModel.tileLimitWarning = false }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
        _preview_showRenameSheet: Bool = false,
        _preview_targetCategoryID: UUID? = nil,
        _preview_renameText: String = ""
    ) {
        self.viewModel = viewModel
        _showRenameSheet = State(initialValue: _preview_showRenameSheet)
        _targetCategoryID = State(initialValue: _preview_targetCategoryID)
        _renameText      = State(initialValue: _preview_renameText)
    }
}
#endif


#if DEBUG
#Preview("History (dumb)") {
    let theme = ThemeManager()
    let hist  = HistoryVM(persistence: PersistenceActor()) // no seeding
    
    HistoryV(viewModel: hist)
        .environmentObject(theme)
        .environmentObject(hist)
        .frame(maxWidth: 430)
}
#endif
