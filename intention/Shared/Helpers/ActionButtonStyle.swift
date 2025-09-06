//
//  ActionButtonStyle.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.

import SwiftUI

struct PrimaryActionStyle: ButtonStyle {
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(palette.accent.opacity(configuration.isPressed ? 0.85 : 1.0))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SecondaryActionStyle: ButtonStyle {
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(palette.surface)
            .foregroundStyle(palette.text)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension View {
    func primaryActionStyle(screen: ScreenName) -> some View {
        modifier(_ButtonStyleWrapper(style: PrimaryActionStyle(palette: ThemeManager().palette(for: screen))))
    }
    func secondaryActionStyle(screen: ScreenName) -> some View {
        modifier(_ButtonStyleWrapper(style: SecondaryActionStyle(palette: ThemeManager().palette(for: screen))))
    }
}

/// Helper to apply ButtonStyle inside a View modifier chain
private struct _ButtonStyleWrapper<S: ButtonStyle>: ViewModifier {
    let style: S
    func body(content: Content) -> some View { content.buttonStyle(style) }
}
