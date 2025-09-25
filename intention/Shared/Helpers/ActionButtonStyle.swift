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
            .foregroundStyle(Color.intText)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(palette.primary)
        // .background(palette.accent.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1.0) : 0.45))        // if pressed
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SecondaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.intText)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(palette.primary)
            .background(palette.accent.opacity(configuration.isPressed ? 0.8 : 1.0))
            .overlay(   RoundedRectangle(cornerRadius: 12, style: .continuous) .stroke(palette.accent, lineWidth: 2) )
            .clipShape( RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}
struct RecalibrationActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var scheme
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.intText)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(palette.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
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
