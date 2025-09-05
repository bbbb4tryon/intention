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

enum ThemeVariant: CaseIterable { case `default`, fire, sea }
enum ScreenName: CaseIterable { case focus, history, settings }

struct ThemePalette {
    // Core semantic tokens used by Page/Card/Buttons/Text
    let background: Color
    let card: Color
    let border: Color
    let accent: Color
    let danger: Color
    let textPrimary: Color
    let textSecondary: Color
}

//MARK: ThemeManager maps (variant, screen) → palette
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
    
    /// Use this for **static** copy in views (headers, labels, captions, body).
    /// Prefer this over sprinkling `.font(...)` and `.foregroundStyle(...)` manually.
    func styledText(_ content: String, as role: TextRole, in screen: ScreenName) -> some View {
        let font  = fontTheme.toFont(Self.fontStyle(for: role))
        let color = Self.color(for: role, palette: palette(for: screen))
        return Text(content).font(font).foregroundStyle(color)
    }
    
    // MARK: - Internal mapping
    
    private static func fontStyle(for role: TextRole) -> Font.TextStyle {
        switch role {
        case .largeTitle: .largeTitle
        case .header:     .title
        case .section:    .title2
        case .title3:     .title3
        case .label, .action: .headline
        case .body, .tile: .body
        case .secondary:  .subheadline
        case .caption:    .caption
        }
    }
    
    private static func color(for role: TextRole, palette: ScreenStylePalette) -> Color {
        switch role {
        case .header, .section, .title3, .body, .tile, .largeTitle:
            return palette.text
        case .secondary, .caption:
            return palette.textSecondary
        case .label:
            return palette.primary
        case .action:
            // For button **labels**, the button style owns color. If needed elsewhere:
            return palette.accent
        }
    }
}

// MARK: - Theme Support Types

enum AppColorTheme: String, CaseIterable {
    case `default`, sea, fire
    
    var displayName: String {
        switch self {
        case .default: "Default"
        case .sea:     "Sea"
        case .fire:    "Fire"
        }
    }
    
    /// One accent per theme for **consistency** across screens.
    private var accent: Color {
        switch self {
        case .default: .intSeaGreen
        case .sea:     Color(red: 0.35, green: 0.75, blue: 1.0)
        case .fire:    Color(red: 1.0, green: 0.5,  blue: 0.0)
        }
    }
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch self {
            
            // ---------- DEFAULT ----------
        case .default:
            let baseBackground: Color = .intTan
            let textPrimary: Color   = .intCharcoal
            let textSecondary: Color = .intCharcoal.opacity(0.72)
            
            switch screen {
            case .homeActiveIntentions:
                return .init(
                    primary:   .intGreen,
                    background: baseBackground,
                    surface:   .intTan.opacity(0.2),
                    accent:    accent,
                    text:      textPrimary,
                    textSecondary: textSecondary,
                    success:   .green,
                    warning:   .yellow,
                    danger:    .red,
                    border:    .black.opacity(0.12)
                )
                
            case .history, .settings:
                return .init(
                    primary:   .intGreen,
                    background: baseBackground,
                    surface:   .intTan.opacity(0.2),
                    accent:    accent,
                    text:      textPrimary,
                    textSecondary: textSecondary,
                    success:   .green,
                    warning:   .yellow,
                    danger:    .red,
                    border:    .black.opacity(0.12)
                )
                
            case .recalibrate:
                // Fix AA: no 40% black on tinted blue; use solid dark text & stronger bg.
                return .init(
                    primary:   .intSeaGreen,
                    background: Color.blue.opacity(0.20),
                    surface:   .intTan.opacity(0.2),
                    accent:    accent,
                    text:      .black,                  // ↑ contrast
                    textSecondary: .black.opacity(0.70),
                    success:   .green,
                    warning:   .yellow,
                    danger:    .red,
                    border:    .black.opacity(0.10)
                )
                /// a tad more neutral (slightly higher surface)
            case .membership:
                return .init(
                    primary:   .intMint,
                    background: Color(.systemGroupedBackground),
                    surface:   .white.opacity(0.96),
                    accent:    accent,            // same accent for consistency!
                    text:      .intCharcoal,
                    textSecondary: .intCharcoal.opacity(0.72),
                    success:   .green,
                    warning:   .yellow,
                    danger:    .red,
                    border:    .black.opacity(0.10)
                )
            }
            
            // ---------- SEA ----------
            case .sea:
                let bg = Color(red: 0.02, green: 0.12, blue: 0.28)
                let tx = Color(red: 0.85, green: 0.92, blue: 1.0)
                return switch screen {
                case .homeActiveIntentions:
                    .init(primary: Color(red: 0.00, green: 0.30, blue: 0.70),
                          background: bg,
                          surface: .white.opacity(0.08),
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.78),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.15))
                case .history:
                    .init(primary: Color(red: 0.12, green: 0.45, blue: 0.75),
                          background: bg.opacity(0.96),
                          surface: .white.opacity(0.06),
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.78),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.15))
                case .settings:
                    .init(primary: Color(red: 0.00, green: 0.28, blue: 0.62),
                          background: bg,
                          surface: .white.opacity(0.08),
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.78),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.15))
                case .recalibrate:
                    .init(primary: Color(red: 0.00, green: 0.12, blue: 0.22),
                          background: Color(red: 0.00, green: 0.30, blue: 0.60).opacity(0.80),
                          surface: .white.opacity(0.10),
                          accent: accent,
                          text: .white, textSecondary: .white.opacity(0.85),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.18))
                case .membership:
                    .init(primary: Color(red: 0.00, green: 0.28, blue: 0.62), // match settings
                          background: bg,                                    // dark theme background
                          surface: .white.opacity(0.12),                     // slightly higher for readability
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.85),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.18))
                }

            
            // ---------- FIRE ----------
        case .fire:
            let bg = Color(red: 0.16, green: 0.02, blue: 0.00)
            let tx = Color(red: 1.00, green: 0.90, blue: 0.78)
            return switch screen {
            case .homeActiveIntentions:
                    .init(primary: Color(red: 0.80, green: 0.22, blue: 0.02),
                          background: bg,
                          surface: .white.opacity(0.07),
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.78),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.14))
            case .history:
                    .init(primary: Color(red: 0.72, green: 0.32, blue: 0.06),
                          background: bg.opacity(0.96),
                          surface: .white.opacity(0.06),
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.78),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.14))
            case .settings:
                    .init(primary: Color(red: 0.88, green: 0.12, blue: 0.02),
                          background: bg,
                          surface: .white.opacity(0.07),
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.78),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.14))
            case .recalibrate:
                    .init(primary: .black,
                          background: Color(red: 0.55, green: 0.02, blue: 0.02),
                          surface: .white.opacity(0.08),
                          accent: accent,
                          text: .white, textSecondary: .white.opacity(0.85),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.16))
            case .membership:
                    .init(primary: Color(red: 0.88, green: 0.12, blue: 0.02), // match settings
                          background: bg,
                          surface: .white.opacity(0.12),                      // slightly higher for readability
                          accent: accent,
                          text: tx, textSecondary: tx.opacity(0.85),
                          success: .green, warning: .yellow, danger: .red, border: .white.opacity(0.16))
            }
        }
    }
}

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

enum ScreenName { case homeActiveIntentions, history, settings, recalibrate, membership }

struct ScreenStylePalette {
    let primary: Color          // secondary button bg / highlights
    let background: Color       // page background
    let surface: Color          // cards, bars
    let accent: Color           // primary CTA color (consistent)
    let text: Color
    let textSecondary: Color
    let success: Color
    let warning: Color
    let danger: Color
    let border: Color
}

enum TextRole {
    case largeTitle, header, section, title3, label, body, tile, secondary, caption, action
}

// MARK: - Preview Convenience
extension View {
    func previewTheme() -> some View {
        self.environmentObject(ThemeManager())
    }
}
