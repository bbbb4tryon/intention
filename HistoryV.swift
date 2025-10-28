//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 10/27/25.
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
                            },
                            onDelete: { id in
                                targetCategoryID = id
                                showDeleteConfirm = true
                            }
                        )
                        .id(category.id)
                        //                        .padding(.vertical, 12)
                        //                        .padding(.horizontal, 16)
                        //                        .environmentObject(theme)
                        // -- category separator --
                        Rectangle()
                            .fill(colorBorder)
                            .frame(height: 1)
                            .padding(.vertical, 4)
                    }
                }
                //                Divider().overlay(Color.intTan)
                //                .padding(.vertical, 12)
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
                    T("Archive capped at 200; oldest items were removed.", .caption)
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
        
//        // Organizer overlay (your fullScreenCover is driven by isOrganizing)
//            .onReceive(NotificationCenter.default.publisher(for: .devOpenOrganizerOverlay)) { _ in
//                withAnimation { isOrganizing = true }
//            }
        
        // Error overlay
//            .onReceive(NotificationCenter.default.publisher(for: .debugShowSampleError)) { _ in
//                showErrorOverlay = true
//            }
//            .overlay {
//                if showErrorOverlay {
//                    ErrorOverlayV(onClose: { showErrorOverlay = false })
//                }
//            }
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
                        onMoveTile: { tile, fromID, toID in
                            Task { @MainActor in
                                do { try await viewModel.moveTileThrowing(tile, from: fromID, to: toID) }
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
        Spacer(minLength: 0)
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