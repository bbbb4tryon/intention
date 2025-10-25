//
//  ActionButtonStyle.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.

import SwiftUI

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundStyle(palette.text)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fillColor(isPressed: configuration.isPressed))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func fillColor(isPressed: Bool) -> Color {
        let base = palette.accent
        if !isEnabled { return base.opacity(0.85) }         // slightly dim
        return isPressed ? base.opacity(0.90) : base
    }
}

struct SecondaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundStyle(palette.surface)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fillColor(isPressed: configuration.isPressed))
            )
            .clipShape( RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private func fillColor(isPressed: Bool) -> Color {
        let base = palette.surface.opacity(0.80)
        if !isEnabled { return base.opacity(0.70) }     // slightly dim
        return isPressed ? base.opacity(0.85) : base
    }
}
struct RecalibrationActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundStyle(palette.accent)
            .padding(.vertical, 12)
            .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fillColor(isPressed: configuration.isPressed))
        )
        .clipShape( RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private func fillColor(isPressed: Bool) -> Color {
        let base = palette.accent
        if !isEnabled { return base.opacity(0.85) }         // slightly dim
        return isPressed ? base.opacity(0.90) : base
    }
}

extension View {
    func primaryActionStyle(screen: ScreenName) -> some View {          modifier(_PrimaryActionStyleMod(screen: screen)) }
    func secondaryActionStyle(screen: ScreenName) -> some View {        modifier(_SecondaryActionStyleMod(screen: screen)) }
    func recalibrationActionStyle(screen: ScreenName) -> some View {    modifier(_RecalibrationActionStyleMod(screen: screen)) }
}

// env-aware wrapper (replaces the current one that calls ThemeManager())
private struct _PrimaryActionStyleMod: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    func body(content: Content) -> some View {
        let p = theme.palette(for: screen)
        content.buttonStyle(PrimaryActionStyle(palette: p))
    }
}
// env-aware wrapper (replaces the current one that calls ThemeManager())
private struct _SecondaryActionStyleMod: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    func body(content: Content) -> some View {
        let p = theme.palette(for: screen)
        content.buttonStyle(SecondaryActionStyle(palette: p))
    }
}

private struct _RecalibrationActionStyleMod: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    func body(content: Content) -> some View {
        let p = theme.palette(for: screen)
        content.buttonStyle(RecalibrationActionStyle(palette: p))
    }
}

/// Helper to apply ButtonStyle inside a View modifier chain
private struct _ButtonStyleWrapper<S: ButtonStyle>: ViewModifier {
    let style: S
    func body(content: Content) -> some View { content.buttonStyle(style) }
}
