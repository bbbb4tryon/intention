//
//  CategoryHeaderRow.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI

struct CategoryHeaderRow: View {
    @EnvironmentObject var viewModel: HistoryVM
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    let isArchive: Bool
    var autoFocus: Bool = false
    @Binding var newTextTiles: [UUID: String]
    let saveHistory: () -> Void         // so onCommit can Save
    @FocusState private var nameFocused: Bool
    @FocusState private var editingCategoryID: UUID?
    var category: CategoriesModel
    
    // MARK: Validation from PM
    private var vState: ValidationState {
        let msgs = viewModel.categoryValidationMessages[categoryItem.id] ?? []
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    
    var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.down.right.fill")
                TextField("Category", text: $categoryItem.persistedInput)
                    .focused($editingCategoryID, equals: category.id)
                    .focused($nameFocused)
                    .padding(10)
                    .background(.thinMaterial.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 10) .stroke(editingCategoryID == category.id ? .secondary : Color.clear, lineWidth: 1) )
                    .overlay(RoundedRectangle(cornerRadius: 10) .stroke(nameFocused ? .secondary : Color.clear, lineWidth: 1) )
                    .onTapGesture { editingCategoryID = category.id }
                    .onTapGesture { nameFocused }
            }
            .task { if autoFocus { nameFocused = true }
        }
    }
    
//    var body: some View {
//        HStack(spacing: 8) {
//            Image(systemName: isArchive ? "lock.fill" : "folder.fill")
//                .foregroundStyle(isArchive ? .secondary : palette.accent)
//            
//            if isArchive {
//                Text("Archive")
//                    .font(fontTheme.toFont(.title3))
//                    .foregroundStyle(palette.textSecondary)
//                Spacer()
//                CountBadge_Archive(fontTheme: fontTheme, count: categoryItem.tiles.count)
//            } else {
//                VStack(alignment: .leading, spacing: 4) {
//                    ZStack(alignment: .leading) {
//                        if categoryItem.persistedInput.isEmpty {
//                            Text("Name this category")
//                                .font(fontTheme.toFont(.caption))
//                                .foregroundStyle(palette.textSecondary)
//                                .padding(.horizontal, 12)
//                        }
//                        TextField("", text: $categoryItem.persistedInput, onCommit: saveHistory)
//                            .textInputAutocapitalization(.words)
//                            .disableAutocorrection(true)
//                            .focused($nameFocused)
//                            .validatingField(state: vState, palette: palette)
//                            .accessibilityLabel("Category name")
//                    }
//                    
//                    ValidationCaption(state: vState, palette: palette)
//                }
//                Spacer()
//                CountBadge_Archive(fontTheme: fontTheme, count: categoryItem.tiles.count)
//
//                Button {
//                    newTextTiles[categoryItem.id] = newTextTiles[categoryItem.id] ?? ""
//                } label: {
//                    Image(systemName: "plus.circle.fill")
//                        .foregroundStyle(palette.accent)
//                }
//                .accessibilityLabel("Add tile")
//            }
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .onAppear { if autoFocus && !isArchive { nameFocused = true } }
//    }
}

#if DEBUG
#Preview("CategoryHeaderRow (direct)") {
    MainActor.assumeIsolated {
        let theme = ThemeManager()
        let palette = theme.palette(for: .settings)

        return CategoryHeaderRow(
            categoryItem: .constant(CategoriesModel(persistedInput: "Work")),
            palette: palette,
            fontTheme: theme.fontTheme,
            newTextTiles: .constant([:]),
            saveHistory: {},
            isArchive: false
        )
        .environmentObject(HistoryVM(persistence: PreviewMocks.persistence))
        .environmentObject(theme)
        .previewTheme()
    }
}
#endif
