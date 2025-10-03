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
    let palette: ScreenStylePalette
    
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)                                 // no background/box
            .foregroundStyle(palette.textSecondary)                   // Always charcoal text
            .tint(palette.text)                                     // selection = charcoal
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                // transparent fill, allow parent view background to show throw
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                // Set stroke color based on validation state
                    .stroke(state.isInvalid ? palette.danger : palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension View {
    func validatingField(state: ValidationState, palette: ScreenStylePalette) -> some View {
        modifier(ValidatingField(state: state, palette: palette))
    }
}
