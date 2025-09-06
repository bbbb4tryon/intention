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
    @Binding var newTextTiles: [UUID: String]
    let saveHistory: () -> Void         // so onCommit can Save
    let isArchive: Bool
    var autoFocus: Bool = false
    @FocusState private var nameFocused: Bool
    
    // MARK: Validation from PM
    private var vState: ValidationState {
        let msgs = viewModel.categoryValidationMessages[categoryItem.id] ?? []
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isArchive ? "lock.fill" : "folder.fill")
                .foregroundStyle(isArchive ? .secondary : palette.accent)
            
            if isArchive {
                Text("Archive")
                    .font(fontTheme.toFont(.title3))
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                CountBadge_Archive(fontTheme: fontTheme, count: categoryItem.tiles.count)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .leading) {
                        if categoryItem.persistedInput.isEmpty {
                            Text("Name this category")
                                .font(fontTheme.toFont(.caption))
                                .foregroundStyle(palette.textSecondary)
                                .padding(.horizontal, 12)
                        }
                        TextField("", text: $categoryItem.persistedInput, onCommit: saveHistory)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .focused($nameFocused)
                            .validatingField(state: vState, palette: palette)
                            .accessibilityLabel("Category name")
                    }
                    
                    ValidationCaption(state: vState, palette: palette)
                }
                Spacer()
                CountBadge_Archive(fontTheme: fontTheme, count: categoryItem.tiles.count)

                Button {
                    newTextTiles[categoryItem.id] = newTextTiles[categoryItem.id] ?? ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(palette.accent)
                }
                .accessibilityLabel("Add tile")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear { if autoFocus && !isArchive { nameFocused = true } }
    }
}

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
