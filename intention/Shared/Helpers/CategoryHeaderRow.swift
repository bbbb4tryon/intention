//
//  CategoryHeaderRow.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI

struct CategoryHeaderRow: View {
    @Binding var categoryItem: CategoriesModel
    let palette: ScreenStylePalette
    let fontTheme: AppFontTheme
    @Binding var newTextTiles: [UUID: String]

    var body: some View {
        HStack {
            TextField("Category", text: $categoryItem.persistedInput)
                .font(fontTheme.toFont(.title3))
                .foregroundStyle(palette.text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .textInputAutocapitalization(.sentences)
                .lineLimit(1)

            Button {
                newTextTiles[categoryItem.id] = newTextTiles[categoryItem.id] ?? ""
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(palette.accent)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
}
