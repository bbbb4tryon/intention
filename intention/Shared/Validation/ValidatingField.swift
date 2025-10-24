//
//  ValidatingField.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

/// Text always charcoal; change border color when invalid:
///         Visual treatment for validated fields using your ScreenStylePalette tokens
struct ValidatingField: ViewModifier {
    let state: ValidationState
    let p: ScreenStylePalette
    
    // --- Local Color Definitions ---
    let textSecondary = Color(red: 0.286, green: 0.290, blue: 0.290)
    let colorDanger = Color.red
    let colorBorder = Color(red: 0.286, green: 0.290, blue: 0.290).opacity(0.4) // or use neutralBorderColor: Color
    
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)                                 // no background/box
            .foregroundStyle(textSecondary)                   // Always charcoal text
            .tint(p.text)                                     // selection = charcoal
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                // transparent fill, allow parent view background to show throw
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                // Set stroke color based on validation state
                    .stroke(state.isInvalid ? colorDanger : colorBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension View {
    func validatingField(
        state: ValidationState,
        palette: ScreenStylePalette
    ) -> some View {
        modifier(
            ValidatingField(state: state, p: palette)
        )
    }
}
