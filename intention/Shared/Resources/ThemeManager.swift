//
//  AppThemeManager.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

// All components are colocated HERE
/* NOTE: adjusting colors:
    lighten: example of background property was deep blue
 - adjust `background` property within `ScreenStylePalette` for each `ScreenName` in the `.sea` case
 */
// MARK: - ThemeManager (Environmental Object)
final class ThemeManager: ObservableObject {
    //  Keep @AppStorage for write-backs
    @AppStorage("selectedColorTheme") private var colorRaw: String = AppColorTheme.default.rawValue
    @AppStorage("selectedFontTheme") private var fontRaw: String = AppFontTheme.serif.rawValue
    
    @Published var colorTheme: AppColorTheme {
        didSet {    colorRaw = colorTheme.rawValue }
    }
    
    @Published var fontTheme: AppFontTheme {
        didSet {    fontRaw = fontTheme.rawValue    }
    }
    
    // Use a static helper, gets the AppStorage values without touching `self` in `init`
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
            case .secondary, .caption: return palette.text.opacity(0.7)
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
            case .homeActiveIntentions: return .init(primary: .intGreen, background: .intTan, accent: .intSeaGreen, text: .intCharcoal)
            case .history: return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intCharcoal)
            case .settings: return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intCharcoal)
            case .recalibrate: return .init(primary: .intSeaGreen, background: .blue.opacity(0.3), accent: .intGreen, text: .black.opacity(0.4))
            }
        case .sea:
            switch screen {
                       case .homeActiveIntentions: return .init(primary: Color(red: 0.0, green: 0.2, blue: 0.8), background: Color(red: 0.0, green: 0.1, blue: 0.3), accent: Color(red: 0.2, green: 0.6, blue: 0.9), text: Color(red: 0.8, green: 0.9, blue: 1.0))
                       case .history: return .init(primary: Color(red: 0.1, green: 0.4, blue: 0.7), background: Color(red: 0.0, green: 0.15, blue: 0.35), accent: Color(red: 0.4, green: 0.8, blue: 1.0), text: Color(red: 0.7, green: 0.8, blue: 0.9))
                       case .settings: return .init(primary: Color(red: 0.0, green: 0.3, blue: 0.6), background: Color(red: 0.0, green: 0.1, blue: 0.4), accent: Color(red: 0.3, green: 0.7, blue: 1.0), text: Color(red: 0.8, green: 0.9, blue: 1.0))
                       case .recalibrate: return .init(primary: Color(red: 0.0, green: 0.1, blue: 0.2), background: Color(red: 0.0, green: 0.3, blue: 0.6).opacity(0.8), accent: Color(red: 0.6, green: 0.9, blue: 1.0), text: .white)
                       }
        case .fire:
            switch screen {
                       case .homeActiveIntentions: return .init(primary: Color(red: 0.8, green: 0.2, blue: 0.0), background: Color(red: 0.2, green: 0.0, blue: 0.0), accent: Color(red: 1.0, green: 0.5, blue: 0.0), text: Color(red: 1.0, green: 0.8, blue: 0.6))
                       case .history: return .init(primary: Color(red: 0.7, green: 0.3, blue: 0.0), background: Color(red: 0.3, green: 0.0, blue: 0.0), accent: Color(red: 1.0, green: 0.6, blue: 0.0), text: Color(red: 1.0, green: 0.9, blue: 0.7))
                       case .settings: return .init(primary: Color(red: 0.9, green: 0.1, blue: 0.0), background: Color(red: 0.1, green: 0.0, blue: 0.0), accent: Color(red: 1.0, green: 0.4, blue: 0.0), text: Color(red: 1.0, green: 0.7, blue: 0.5))
                       case .recalibrate: return .init(primary: .black, background: Color(red: 0.6, green: 0.0, blue: 0.0), accent: Color(red: 1.0, green: 0.7, blue: 0.0), text: .white)
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
