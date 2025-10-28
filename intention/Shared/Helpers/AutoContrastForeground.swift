//
//  AutoContrastForeground.swift
//  intention
//
//  Created by Benjamin Tryon on 10/27/25.
//


import SwiftUI

/// Applies a foregroundColor that maintains at least `target` contrast against a *known* background color.
/// Use this when your background is a solid `Color` (or an *average* of a gradient).
public struct AutoContrastForeground: ViewModifier {
    let preferred: Color
    let background: Color
    let target: Double

    public func body(content: Content) -> some View {
        let safe = Color.idealForeground(preferred: preferred, on: background, target: target)
        return content.foregroundStyle(safe)
    }
}

public extension View {
    /// Use when you *know* the effective background color under this text.
    func autoContrastForeground(preferred: Color, on background: Color, target: Double = 6.1) -> some View {
        modifier(AutoContrastForeground(preferred: preferred, background: background, target: target))
    }
}
