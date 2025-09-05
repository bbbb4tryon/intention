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
    
    // MARK: - Local helpers
    private var hasValidationIssues: Bool {
        !(viewModel.categoryValidationMessages[categoryItem.id]?.isEmpty ?? true)
    }
    private var borderColor: Color { hasValidationIssues ? .red : .clear }
    
    private var p: ThemePalette { theme.palette(for: .history) }
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .history))    }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isArchive ? "lock.fill" : "folder.fill")
                .foregroundStyle(isArchive ? .secondary : palette.accent)
            
            if isArchive {
                theme.styledText("Archive", as: .header, in: .history)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                TextField(T("Name this category", .caption),
                          text: $categoryItem.persistedInput,
                          onCommit: saveHistory
                )
                .focused($nameFocused)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.words)
                .lineLimit(1)
                .border(borderColor, width: 1)                                  
                .background(hasValidationIssues ? Color.red.opacity(0.2) : Color.clear)
                .onChange(of: categoryItem.persistedInput ) { newValue in
                    viewModel.validateCategory(id: categoryItem.id, title: newValue)
                }
                
                /// Display validation messages from the view model
                if let messages = viewModel.categoryValidationMessages[categoryItem.id], !messages.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(messages, id: \.self) { message in
                            Text(message)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                CountBadge_Archive(fontTheme: fontTheme, count: categoryItem.tiles.count)
                
                Button {
                    newTextTiles[categoryItem.id] = newTextTiles[categoryItem.id] ?? "" } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add tile")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear { if autoFocus { nameFocused = true } }
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
