// Text+Style.swift
// intention


// Centralized semantic text styling

import SwiftUI

// MARK: - Semantic Roles for Text Styling
enum TextRole {
    case header
    case section
    case label
    case tile
    case body
    case caption
    case secondary
    case action
}

// MARK: - Text Extension for Semantic Styling
extension Text {
    static func styled(
        _ content: String,
        as role: TextRole,
        using font: AppFontTheme,
        in palette: ScreenStylePalette
    ) -> some View {
        Text(content)
            .font(font.toFont(Self.fontStyle(for: role)))
            .foregroundStyle(Self.color(for: role, palette: palette))
    }

    private static func fontStyle(for role: TextRole) -> Font.TextStyle {
        switch role {
        case .header: return .title
        case .section: return .title2
        case .label, .tile: return .body
        case .body: return .body
        case .caption: return .caption
        case .secondary: return .subheadline
        case .action: return .headline
        }
    }

    private static func color(for role: TextRole, palette: ScreenStylePalette) -> Color {
        switch role {
        case .header, .section, .body, .tile: return palette.text
        case .secondary, .caption: return palette.accent
        case .label: return palette.primary
        case .action: return palette.accent
        }
    }
}
