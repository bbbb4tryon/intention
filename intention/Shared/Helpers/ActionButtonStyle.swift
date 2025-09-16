//
//  ActionButtonStyle.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.

import SwiftUI

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.7))
            .background(palette.accent.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1.0) : 0.45))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SecondaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(palette.text.opacity(isEnabled ? 1 : 0.6))
            .background(palette.surface.opacity(configuration.isPressed ? 0.9 : 1.0))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
struct RecalibrationActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ScreenStylePalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.yellow.opacity(isEnabled ? 1 : 0.7))
            .background(palette.success.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1.0) : 0.45))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// env-aware wrapper (replaces the current one that calls ThemeManager())
private struct PrimaryActionStyleEnv: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    func body(content: Content) -> some View {
        content.buttonStyle(PrimaryActionStyle(palette: theme.palette(for: screen)))
    }
}
// env-aware wrapper (replaces the current one that calls ThemeManager())
private struct SecondaryActionStyleEnv: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    func body(content: Content) -> some View {
        content.buttonStyle(SecondaryActionStyle(palette: theme.palette(for: screen)))
    }
}

private struct RecalibrationActionStyleEnv: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    func body(content: Content) -> some View {
        content.buttonStyle(RecalibrationActionStyle(palette: theme.palette(for: .recalibrate)))
    }
}

extension View {
    func primaryActionStyle(screen: ScreenName) -> some View { modifier(PrimaryActionStyleEnv(screen: screen)) }
    func secondaryActionStyle(screen: ScreenName) -> some View { modifier(SecondaryActionStyleEnv(screen: screen)) }
    func recalibrationActionStyle() -> some View { modifier(RecalibrationActionStyleEnv()) }
}

/// Helper to apply ButtonStyle inside a View modifier chain
private struct _ButtonStyleWrapper<S: ButtonStyle>: ViewModifier {
    let style: S
    func body(content: Content) -> some View { content.buttonStyle(style) }
}
