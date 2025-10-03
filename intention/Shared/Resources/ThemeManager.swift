//
//  AppThemeManager.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI
/*
 Make color vary by theme+screen, while typography/spacing/components stay identical
 
 The goal: one component system (Page, Card, fonts, paddings) + per-screen palette that swaps only colors when you change variant (“Default/Fire/Sea”)
 */

// Shim: keep code compiling that expects ThemePalette, if any still refer to it!
typealias ThemePalette = ScreenStylePalette
// MARK: - Screens
enum ScreenName { case homeActiveIntentions, history, settings, recalibrate, membership } // FIXME: rename homeActiveIntentions to focus
// MARK: - Text roles
enum TextRole {
    case largeTitle, header, section, title3, label, body, tile, secondary, caption, action, placeholder
}
// MARK: - Per-screen color tokens
struct ScreenStylePalette {
    let primary: Color          // secondary button bg / highlights
    let background: Color       // page background
    let surface: Color          // cards, bars
    let accent: Color           // primary CTA color
    let text: Color
    let textSecondary: Color
    let success: Color
    let warning: Color
    let danger: Color
    let border: Color
    
    struct LinearGradientSpecial {
        let colors: [Color]
        let start: UnitPoint
        let end: UnitPoint
    }
    let gradientBackground: LinearGradientSpecial?      // nil == use `background` color
}
// MARK: - App Font Theme
enum AppFontTheme: String, CaseIterable {
    case serif, rounded, mono
    var displayName: String { self == .serif ? "Serif" : self == .rounded ? "Rounded" : "Mono" }
    func toFont(_ style: Font.TextStyle) -> Font {
        let design: Font.Design = switch self {
        case .serif: .serif
        case .rounded: .rounded
        case .mono: .monospaced
        }
        return .system(style, design: design)
    }
}

// MARK: - App Color Theme → per-screen palettes
enum AppColorTheme: String, CaseIterable {
    case `default`, sea, fire
    
    var displayName: String {
        switch self { case .default: "Default"; case .sea: "Sea"; case .fire: "Fire" }
    }
    /// One accent per theme for consistency
    private var accent: Color {
        switch self {
        case .default: .intSeaGreen
        case .sea:     Color(red: 0.35, green: 0.75, blue: 1.0)
        case .fire:    Color(red: 1.0, green: 0.5, blue: 0.0)
        }
    }
    
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch self {
            
            // ---------- DEFAULT ----------
        case .default:
            let baseBackground: Color = .intTan
            let textPrimary: Color   = .intCharcoal
            let textSecondary: Color = .intCharcoal.opacity(0.85)
            
            switch screen {
            case .homeActiveIntentions, .history, .settings:
                return .init(
                    primary: .intGreen,             // drives CTA fill
                    background: baseBackground,
                    surface: .intTan.opacity(0.7),
                    accent: accent,
                    text: textPrimary,
                    textSecondary: textSecondary,
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .intCharcoal,
                    gradientBackground: nil
                )
                
            case .recalibrate:
                // unchanged – this one was fine
                return .init(
                    primary: .intSeaGreen,      // drives CTA fill
                    background: Color.blue.opacity(0.20),
                    surface: .intTan.opacity(0.7),
                    accent: accent,
                    text: .black,
                    textSecondary: textPrimary,
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .black.opacity(0.10),
                    gradientBackground: .init(
                        colors: [Color.blue.opacity(0.20), Color.blue.opacity(0.85)],
                        start: .topLeading,
                        end: .bottomTrailing
                    )
                )
                
            case .membership:
                return .init(
                    primary: .intMint,
                    background: Color(.systemGroupedBackground),
                    surface: .white.opacity(0.96),
                    accent: accent,
                    text: .intCharcoal,
                    textSecondary: .intCharcoal.opacity(0.72),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .black.opacity(0.10),
                    gradientBackground: nil
                )
            }
            
            // ---------- SEA ----------
        case .sea:
            let bg = Color(red: 0.02, green: 0.12, blue: 0.28)
            let txt = Color(red: 0.85, green: 0.92, blue: 1.0)
            switch screen {
            case .homeActiveIntentions:
                return .init(
                    primary: Color(red: 0.00, green: 0.30, blue: 0.70),
                    background: bg,
                    surface: .white.opacity(0.08),
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.15),
                    gradientBackground: nil
                )
            case .history:
                return .init(
                    primary: Color(red: 0.12, green: 0.45, blue: 0.75),
                    background: bg.opacity(0.96),
                    surface: .white.opacity(0.06),
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.15),
                    gradientBackground: nil
                )
            case .settings:
                return .init(
                    primary: Color(red: 0.00, green: 0.28, blue: 0.62),
                    background: bg,
                    surface: .white.opacity(0.08),
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.15),
                    gradientBackground: nil
                )
            case .recalibrate:
                return .init(
                    primary: Color(red: 0.00, green: 0.12, blue: 0.22),
                    background: Color(red: 0.00, green: 0.30, blue: 0.60).opacity(0.80),
                    surface: .white.opacity(0.10),
                    accent: accent,
                    text: .white,
                    textSecondary: .white.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.18),
                    gradientBackground: nil
                )
            case .membership:
                return .init(
                    primary: Color(red: 0.00, green: 0.28, blue: 0.62), // match settings
                    background: bg,                                      // dark theme background
                    surface: .white.opacity(0.12),                     // slightly higher for readability
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.18),
                    gradientBackground: nil
                )
            }
            // ---------- FIRE ----------
        case .fire:
            let bg = Color(red: 0.16, green: 0.02, blue: 0.00)
            let txt = Color(red: 1.00, green: 0.90, blue: 0.78)
            switch screen {
            case .homeActiveIntentions:
                return .init(
                    primary: Color(red: 0.80, green: 0.22, blue: 0.02),
                    background: bg,
                    surface: .white.opacity(0.07),
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.14),
                    gradientBackground: nil
                )
            case .history:
                return .init(
                    primary: Color(red: 0.72, green: 0.32, blue: 0.06),
                    background: bg.opacity(0.96),
                    surface: .white.opacity(0.06),
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.14),
                    gradientBackground: nil
                )
            case .settings:
                return .init(
                    primary: Color(red: 0.88, green: 0.12, blue: 0.02),
                    background: bg,
                    surface: .white.opacity(0.07),
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.14),
                    gradientBackground: nil
                )
            case .recalibrate:
                return .init(
                    primary: .black,
                    background: Color(red: 0.55, green: 0.02, blue: 0.02),
                    surface: .white.opacity(0.08),
                    accent: accent,
                    text: .white,
                    textSecondary: .white.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.16),
                    gradientBackground: nil
                )
            case .membership:
                return .init(
                    primary: Color(red: 0.88, green: 0.12, blue: 0.02), // match settings
                    background: bg,
                    surface: .white.opacity(0.12),                      // slightly higher for readability
                    accent: accent,
                    text: txt,
                    textSecondary: txt.opacity(0.85),
                    success: .green,
                    warning: .yellow,
                    danger: .red,
                    border: .white.opacity(0.16),
                    gradientBackground: nil
                )
            }
        }
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("selectedColorTheme") private var colorRaw: String = AppColorTheme.default.rawValue
    @AppStorage("selectedFontTheme")  private var fontRaw: String = AppFontTheme.serif.rawValue
    
    @Published var colorTheme: AppColorTheme { didSet { colorRaw = colorTheme.rawValue } }
    @Published var fontTheme: AppFontTheme { didSet { fontRaw  = fontTheme.rawValue  } }
    
    init() {
        let storedColor = UserDefaults.standard.string(forKey: "selectedColorTheme") ?? AppColorTheme.default.rawValue
        let storedFont  = UserDefaults.standard.string(forKey: "selectedFontTheme")  ?? AppFontTheme.serif.rawValue
        self.colorTheme = AppColorTheme(rawValue: storedColor) ?? .default
        self.fontTheme  = AppFontTheme(rawValue: storedFont)  ?? .serif
    }
    
    func palette(for screen: ScreenName) -> ScreenStylePalette {
        colorTheme.colors(for: screen)
    }
    
    func styledText(_ content: String, as role: TextRole, in screen: ScreenName) -> Text {
        let font  = fontTheme.toFont(Self.fontStyle(for: role))
        let color = Self.color(for: role, palette: palette(for: screen))
        let weight: Font.Weight = switch role {
        case .largeTitle:   .bold
        case .header:       .semibold
        case .section:      .semibold
        case .title3:       .semibold
        case .label:        .medium
        case .action:       .semibold
        default:            .regular
        }
        
        return Text(content).font(font).fontWeight(weight).foregroundColor(color)
    }
    
    // MARK: Style mapping
    static func fontStyle(for role: TextRole) -> Font.TextStyle {
        switch role {
        case .largeTitle:   .largeTitle
        case .header:       .largeTitle
        case .section:      .title2
        case .title3:       .title3
        case .label:        .headline
        case .action:       .headline
        case .body:         .body
        case .tile:         .body
        case .secondary:    .subheadline
        case .placeholder:  .subheadline
        case .caption:      .caption
        }
    }
    
    static func color(for role: TextRole, palette: ScreenStylePalette) -> Color {
        switch role {
        case .header, .section, .title3, .body, .tile, .largeTitle:
            return palette.text
        case .secondary, .caption, .placeholder:
            return palette.textSecondary
        case .label:
            return palette.text
        case .action:
            // ButtonStyles typically color the label; this keeps Action readable elsewhere.
            return .intText
        }
    }
}

// MARK: - defines consistent, app-wide color of button text
extension Color {
    static let intText = Color(red: 0.96, green: 0.96, blue: 0.96)     // #F5F5F5
    static let btnTextLight = intText     // #F5F5F5
    static let btnTextDark  = Color(red: 0.99, green: 0.99, blue: 0.99)     // #FDFDFD
}

// MARK: - Preview Convenience
extension View {
    func previewTheme() -> some View {
        self.environmentObject(ThemeManager())
    }
}
