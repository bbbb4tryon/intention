//
//  CategoryHeaderRow.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI

struct CategoryHeaderRow: View {
    @EnvironmentObject var viewModel: HistoryVM             /// Or as an internal private let with init()?
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    @Binding var newTextTiles: [UUID: String]
    let saveHistory: () -> Void         // so onCommit can Save
    let isArchive: Bool
    var autoFocus: Bool = false
    
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isArchive ? "lock.fill" : "folder.fill")
                .foregroundStyle(isArchive ? .secondary : palette.accent)
            
            if isArchive {
                Text("Archive")
                    .font(fontTheme.toFont(.headline))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                TextField("Name this category",
                          text: $categoryItem.persistedInput,
                          onCommit: saveHistory
                )
                .focused($nameFocused)
                .font(fontTheme.toFont(.headline))
                .disableAutocorrection(true)
                .textInputAutocapitalization(.words)
                .lineLimit(1)
                .border(borderColor, width: 1)                                  // FIXME: is this fucking up the layout?
                .background(viewModel.validationMessages.isEmpty ? palette.accent : Color.red.opacity(0.2)) // FIXME: is this fucking up the layout?
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
        
        
        // FIXME: is this fucking up the layout?
        /// Helper *property* to determine border color
        var borderColor: Color {
            let displayValidationMessages = viewModel.categoryValidationMessages[categoryItem.id]?.isEmpty == false
            return displayValidationMessages ? .red : .clear
        }
    }
}

