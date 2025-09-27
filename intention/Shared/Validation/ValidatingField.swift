//
//  ValidatingField.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

/// Visual treatment for validated fields using your ScreenStylePalette tokens
struct ValidatingField: ViewModifier {
    let state: ValidationState
    let palette: ScreenStylePalette

    func body(content: Content) -> some View {
        content
            .padding(12)
            .foregroundStyle(palette.text)                          // Always charcoal text
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.text)        // charcoal-ish box
            )
            .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(state.isInvalid ? palette.danger : palette.text, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension View {
    func validatingField(state: ValidationState, palette: ScreenStylePalette) -> some View {
        modifier(ValidatingField(state: state, palette: palette))
    }
}
