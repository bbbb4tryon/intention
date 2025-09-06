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
            .background(palette.surface.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(state.isInvalid ? palette.danger : palette.border, lineWidth: 1)
            )
            .foregroundStyle(state.isInvalid ? palette.danger : palette.text)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension View {
    func validatingField(state: ValidationState, palette: ScreenStylePalette) -> some View {
        modifier(ValidatingField(state: state, palette: palette))
    }
}
