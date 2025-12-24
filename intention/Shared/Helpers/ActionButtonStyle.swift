//
//  ActionButtonStyle.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.

import SwiftUI

// MARK: - PrimaryActionStyle
// filled with Accent, white text
struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ScreenStylePalette
    
    func makeBody(configuration: Configuration) -> some View {
        let base = palette.accent
        let pressed = configuration.isPressed
        
        return configuration.label
            .font(.headline)
            // always, for contrast
            .foregroundStyle(Color.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(base)
                    // vertical gloss - light mode shows more; dark mode gently
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(pressed ? 0.08 : 0.16),
                                Color.white.opacity(0.00)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                  )
                        // 1pt highlight stroke - definition on dark
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                        // a lift/shadow that reacts to press
                            .shadow(color: Color.black.opacity(isEnabled ? (pressed ? 0.10 : 0.22) : 0.00 ),
                                    radius: pressed ? 6 : 12, y: pressed ? 2 : 6)
                    )
            // main shadow for depth
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)

            .shadow(color: Color.intGreen.opacity(0.15), radius: 12, x: 0, y: 4)
                    .scaleEffect(pressed ? 0.985 : 1.0)                         // press feedback
                    .opacity(isEnabled ? 1.0 : 0.85)                            // disabled dim
                    .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: Secondary (surface chip with tinted text)
struct SecondaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ScreenStylePalette

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let fill = palette.surfaces.opacity(0.9)

        return configuration.label
            .font(.headline)
            .foregroundStyle(palette.text.opacity(0.9))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(palette.text.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(isEnabled ? (pressed ? 0.06 : 0.14) : 0.0),
                            radius: pressed ? 3 : 8, y: pressed ? 1 : 3)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            .scaleEffect(pressed ? 0.992 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.75)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: Recalibration (outline / inverted accent)
struct RecalibrationActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ScreenStylePalette

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let stroke = palette.accent

        return configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(palette.surfaces)      // uses dark for text
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.accent.opacity(pressed ? 0.9 : 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(stroke.opacity(pressed ? 0.9 : 1.0), lineWidth: 1.25)
                    )
                    .shadow(color: stroke.opacity(isEnabled ? (pressed ? 0.10 : 0.20) : 0.0),
                            radius: pressed ? 3 : 6, y: pressed ? 1 : 3)
            )
        // Main shadow
                   .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                   // Subtle company green glow
                   .shadow(color: Color.intGreen.opacity(0.12), radius: 10, x: 0, y: 4)
            .scaleEffect(pressed ? 0.992 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.80)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
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
