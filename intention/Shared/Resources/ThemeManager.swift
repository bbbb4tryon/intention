//
//  AppThemeManager.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

// All components are colocated HERE
// MARK: - ThemeManager (Environmental Object)
final class ThemeManager: ObservableObject {
    @AppStorage("selectedColorTheme") private var colorRaw: String = AppColorTheme.default.rawValue
    @AppStorage("selectedFontTheme") private var fontRaw: String = AppFontTheme.serif.rawValue
    
    @Published var colorTheme: AppColorTheme {
        didSet {    colorRaw = colorTheme.rawValue }
    }
    
    @Published var fontTheme: AppFontTheme {
        didSet {    fontRaw = fontTheme.rawValue    }
    }
    
    init()  {
        // Reading from UserDefaults directly - it is what @AppStorage abstracts under the hood
        let storedColor = UserDefaults.standard.string(forKey: "selectedColorTheme") ?? AppColorTheme.default.rawValue
        let storedFont = UserDefaults.standard.string(forKey: "selectedFontTheme") ?? AppFontTheme.serif.rawValue
        
        self.colorTheme = AppColorTheme(rawValue: storedColor) ?? .default
        self.fontTheme = AppFontTheme(rawValue: storedFont) ?? .serif
    }
    func palette(for screen: ScreenName) -> ScreenStylePalette {
            colorTheme.colors(for: screen)
        }

        func styledText(
            _ content: String,
            as role: TextRole,
            in screen: ScreenName
        ) -> some View {
            let font = fontTheme.toFont(Self.fontStyle(for: role))
            let color = Self.color(for: role, palette: palette(for: screen))
            return Text(content).font(font).foregroundStyle(color)
        }

        private static func fontStyle(for role: TextRole) -> Font.TextStyle {
            switch role {
            case .header: return .largeTitle
            case .section: return .title2
            case .label, .tile, .title3: return .body
            case .body: return .body
            case .caption: return .caption
            case .secondary: return .subheadline
            case .action: return .headline
            case .largeTitle: return .largeTitle
            }
        }

        private static func color(for role: TextRole, palette: ScreenStylePalette) -> Color {
            switch role {
            case .header, .section, .body, .tile, .title3: return palette.text
            case .secondary, .caption: return palette.accent
            case .label: return palette.primary
            case .action: return palette.accent
            case .largeTitle: return palette.text
            }
        }
    }

// MARK: - Theme Support Types

enum AppColorTheme: String, CaseIterable {
    case `default`, sea, fire
    
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .sea: return "Sea"
        case .fire: return "Fire"
        }
    }
    
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch self {
        case .default:
            switch screen {
            case .homeActiveIntentions: return .init(primary: .intGreen, background: .intTan, accent: .intSeaGreen, text: .intBrown)
            case .history: return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
            case .settings: return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
            case .recalibrate: return .init(primary: .intSeaGreen, background: .intBrown.opacity(0.3), accent: .intGreen, text: .yellow.opacity(0.4))
            }
        case .sea:
            switch screen {
            case .homeActiveIntentions: return .init(primary: .teal, background: .mint.opacity(0.15), accent: .cyan, text: .blue)
            case .history: return .init(primary: .mint, background: .mint.opacity(0.15), accent: .cyan.opacity(0.4), text: .teal)
            case .settings: return .init(primary: .teal, background: .mint.opacity(0.2), accent: .cyan.opacity(0.5), text: .teal)
            case .recalibrate: return .init(primary: .indigo, background: .teal.opacity(0.2), accent: .mint.opacity(0.6), text: .cyan)
            }
        case .fire:
            switch screen {
            case .homeActiveIntentions: return .init(primary: .orange, background: .pink.opacity(0.1), accent: .red.opacity(0.6), text: .brown)
            case .history: return .init(primary: .orange, background: .pink.opacity(0.15), accent: .red.opacity(0.5), text: .brown)
            case .settings: return .init(primary: .orange, background: .pink.opacity(0.05), accent: .red.opacity(0.4), text: .brown)
            case .recalibrate: return .init(primary: .black.opacity(0.85), background: .red, accent: .orange.opacity(0.3), text: .white)
            }
        }
    }
}

enum AppFontTheme: String, CaseIterable {
    case serif, rounded, mono
    
    var displayName: String {
        switch self {
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .mono: return "Mono"
        }
    }
    
    func toFont(_ style: Font.TextStyle) -> Font {
        let design: Font.Design
        switch self {
        case .serif: design = .serif
        case .rounded: design = .rounded
        case .mono: design = .monospaced
        }
        return .system(style, design: design)
    }
}

// MARK: - Theme Semantic Helpers

enum ScreenName {
    case homeActiveIntentions, history, settings, recalibrate
}

struct ScreenStylePalette {
    let primary: Color
    let background: Color
    let accent: Color
    let text: Color
}

enum TextRole {
    case header, section, label, tile, title3, body, caption, secondary, action, largeTitle
}

// MARK: - Preview Convenience
extension View {
    func previewTheme() -> some View {
        self.environmentObject(ThemeManager())
    }
}
