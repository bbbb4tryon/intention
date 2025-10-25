//
//  AppThemeManager.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI
// views will use local color constants for validation, border, and secondary text
// Shim: keep code compiling that expects ThemePalette, if any still refer to it!
typealias ThemePalette = ScreenStylePalette

// -- Use a material background (which applies a subtle blur/opacity)
//    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
// modern approach in Swift for non-shadow readability.
// It automatically ensures the text's background contrasts with the content behind it, boosting legibility without adding an explicit shadow
// MARK: Screens
enum ScreenName {
    case focus, history, settings, organizer, recalibrate, membership
}
// MARK: Text roles
enum TextRole {
    case largeTitle, header, section, title3, label, body, tile, secondary, caption, action, placeholder
}
// MARK: - Per-screen color tokens
struct ScreenStylePalette {
    let primary: Color          // secondary button bg or highlighting
    let background: Color       // main pages
    let surface: Color          // card color, tab bars, // RENAME
    let accent: Color          // CTA color - use for fill
    let text: Color
    
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

// MARK: Color Constants (Moved from extension to local enums/structs for clarity)
// Color Palette:
// background_light: f6f6f6, background_medium: d9ddc7, surface: c1c1c1, accent: 8ea131, text: 555555, secondary_text_bg: 3e3e36

private enum DefaultColors {
    // R: 246, G: 246, B: 246 (#F6F6F6) - Very light, almost white background
    static let backgroundLight = Color(red: 0.965, green: 0.965, blue: 0.965)
    
    //    // R: 217, G: 221, B: 199 (#D9DDC7) - Tan-gray (used for Recalibrate/Organizer background)
    //    static let backgroundMedium = Color(red: 0.851, green: 0.867, blue: 0.788)
    // R: 217, G: 221, B: 199 (#E0D8CB) - Tan-gray (used for Recalibrate/Organizer background)
    static let backgroundMedium = Color(red: 0.878, green: 0.847, blue: 0.796)
    
    // R: 193, G: 193, B: 193 (#C1C1C1) - Medium gray for cards/surfaces
    static let surface = Color(red: 0.757, green: 0.757, blue: 0.757)
    
    // R: 142, G: 161, B: 49 (#8EA131) - Leaf (filling things like CTA)
    static let accent = Color(red: 0.557, green: 0.631, blue: 0.192)
    
    // R: 85, G: 85, B: 85 (#555555) - Dark Gray (Primary Text)
    static let text = Color(red: 0.333, green: 0.333, blue: 0.333)
}

// MARK: OrganizerOverlay
private enum OrgBG {
    // TopLight and BottomDark are now assigned based on the new backgroundMedium color if needed
    static let topLight = DefaultColors.backgroundLight
    static let bottomDark = DefaultColors.backgroundMedium
}

// MARK: Recalibrate Sheet
private enum RecalibrateBG {
    // -> lighter = #335492, darker #001e64
    // Keep the distinct Recalibrate blues, as they provide high contrast for that screen's specific context.
    static let topLight  = Color(red: 0.2000, green: 0.3294, blue: 0.5725)
    // converted from #001e64
    static let bottomDark = Color(red: 0.0, green: 0.1176, blue: 0.3922)
}

// MARK: Membership Sheet
private enum MembershipBG {
    static let topLight  = Color(red: 0.72, green: 0.86, blue: 1.00)
    static let bottomDark = Color(red: 0.0, green: 0.1176, blue: 0.3922)
}

// MARK: Sea theme
private enum Sea {
    // Light “Close” blue (used as top of gradient & general bg) #73a7f6
    static let topLight  = Color(red: 0.45, green: 0.65, blue: 96)
    // Darker body blue (used as bottom of gradient & accent/tint) #0d53bf
    static let bottomDark = Color(red: 0.05, green: 0.33, blue: 0.75)
}


// MARK: - App Color Theme → per-screen palettes
enum AppColorTheme: String, CaseIterable {
    case `default`, sea
    
    var displayName: String {
        switch self {
        case .default: "Default"
        case .sea: "Sea"
        }
    }
    
    // Show fewer choices in Settings without deleting anything.
    // Change this list whenever you want to expose more/less.
    static var publicCases : [AppColorTheme] { [.default, .sea] }
    
    //    /// One accent per theme for consistency
    //    private var accent: Color {
    //        switch self {
    //        case .default: DefaultColors.accent
    //        case .sea:     Color(red: 0.35, green: 0.75, blue: 1.0)
    //        }
    //    }
    
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch self {
            // ---------- DEFAULT ----------
        case .default:
            
            switch screen {
            case .focus, .history, .settings:
                return .init(
                    primary: DefaultColors.surface,             // Secondary CTA color (gray)
                    background: DefaultColors.backgroundLight,    // Page background
                    surface: DefaultColors.surface.opacity(0.85), // Card/Bar surface (slightly lighter)
                    accent: DefaultColors.accent,               // Primary CTA color (citron)
                    text: DefaultColors.text,                   // Primary text color (dark gray)
                    gradientBackground: nil
                )
                
            case .recalibrate:
                return .init(
                    primary: RecalibrateBG.bottomDark,
                    background: RecalibrateBG.topLight,       // overall background - bg = a lighter hue of blue for "Close" button
                    surface: DefaultColors.surface.opacity(0.08), /* or .white.opacity(0.08),*/ // Card/Bar surface (much lighter)
                    accent: DefaultColors.accent.opacity(0.5),    // CTA fill and accent fill
                    text: DefaultColors.text.opacity(0.08),       // Primary text color (light hue of dark gray)
                    gradientBackground: .init(
                        colors: [(RecalibrateBG.topLight), (RecalibrateBG.bottomDark)],
                        start: .topLeading,
                        end: .bottomTrailing
                    )
                )
                
            case .membership:
                return .init(
//                    primary: DefaultColors.surface,             // Secondary CTA color (gray)
                    primary: DefaultColors.accent,               // Primary CTA color (citron)
                    background: DefaultColors.backgroundLight,    // Page background
                    surface: DefaultColors.surface.opacity(0.96), // Card/Bar surface (slightly lighter)
                    accent: DefaultColors.accent,               // Primary CTA color (citron)
                    text: DefaultColors.text,                   // Primary text color (dark gray)
                    gradientBackground: .init(
                        colors: [(MembershipBG.topLight), (MembershipBG.bottomDark)],
                        start: .topTrailing,
                        end: .bottomLeading
                    )

                )
                
            case .organizer:
                // superior contrast (6.1:1) against the light gradient
                /*#7b6428*/ let organizerText = Color(red: 0.4824, green: 0.3922, blue: 0.1569)
                return .init(
                    primary: DefaultColors.accent,               // Primary CTA color (citron)
                    background: .clear,     // Set to .clear since we rely on the gradient
                    surface: .clear,        // Surface should also be clear to see gradient
                    accent: organizerText, /* Use the dark text color for chrome tint (X button) */
                    text: organizerText.opacity(0.72), // Secondary text is slightly lighter
                    gradientBackground: .init(
                        colors: [OrgBG.topLight, OrgBG.bottomDark],   // Use the light/medium background for organizer gradient
                        start: .top,
                        end: .bottom
                    )
                )
            }
            
            // ---------- SEA ----------
        case .sea:
            // Background: #0B47A3 (Dark Blue)
                        let seaBG = Color(red: 0.043, green: 0.278, blue: 0.639)
                        // Text: #D9EBFF (Very Light Blue)
                        let seaText = Color(red: 0.851, green: 0.922, blue: 1.0)
                        // Accent: #FF8C00 (Orange)
                        let seaAccent = Color(red: 1.0, green: 0.55, blue: 0.0)
       
                    
                    // Standard colors for the Sea gradient
                    let seaGradientColors: [Color] = [Sea.topLight, Sea.bottomDark]

                    switch screen {
                    case .focus, .history, .settings:
                        // These main tabs use solid backgrounds
                        return .init(
                            primary: Color(red: 0.00, green: 0.30, blue: 0.70),
                            background: seaBG,
                            surface: seaText.opacity(0.12),
                            accent: seaAccent,
                            text: seaText,
                            gradientBackground: nil
                        )
                        
                    case .recalibrate:
                        // Unique Gradient Direction: Diagonal
                        return .init(
                            primary: Color(red: 0.00, green: 0.12, blue: 0.22),
                            background: Sea.bottomDark.opacity(0.9),
                            surface: seaText.opacity(0.15),
                            accent: seaAccent,
                            text: .white,
                            gradientBackground: .init(
                                colors: seaGradientColors,
                                start: .topLeading,
                                end: .bottomTrailing // ↖️ Diagonal flow
                            )
                        )
                        
                    case .membership:
                        // Unique Gradient Direction: Horizontal
                        return .init(
                            primary: Color(red: 0.00, green: 0.28, blue: 0.62),
                            background: seaBG,
                            surface: seaText.opacity(0.12),
                            accent: seaAccent,
                            text: seaText,
                            gradientBackground: .init(
                                colors: seaGradientColors,
                                start: .leading,
                                end: .trailing // ➡️ Horizontal flow
                            )
                        )
                        
                    case .organizer:
                        // Unique Gradient Direction: Vertical
                        return .init(
                            primary: Color(red: 0.00, green: 0.28, blue: 0.62),
                            // Background is .clear to ensure the gradient shows through FocusShell
                            background: .clear,
                            surface: seaText.opacity(0.12),
                            accent: seaAccent,
                            text: seaText,
                            gradientBackground: .init(
                                colors: seaGradientColors,
                                start: .top,
                                end: .bottom // ⬇️ Vertical flow
                            )
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

    @Published var colorTheme: AppColorTheme {
        didSet { colorRaw = colorTheme.rawValue }
    }
    @Published var fontTheme: AppFontTheme {
        didSet { fontRaw  = fontTheme.rawValue  }
    }

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
            case .largeTitle: .bold
            case .header:.semibold
            case .section: .semibold
            case .title3:.semibold
            case .label: .medium
            case .action:.semibold
            default: .regular
        }
        return Text(content).font(font).fontWeight(weight).foregroundColor(color)
    }

    // MARK: Style mapping
    static func fontStyle(for role: TextRole) -> Font.TextStyle {
        switch role {
            case .largeTitle: .largeTitle
            case .header: .largeTitle
            case .section: .title2
            case .title3:.title3
            case .label: .headline
            case .action:.headline
            case .body: .body
            case .tile: .body
            case .secondary: .subheadline
            case .placeholder: .subheadline
            case .caption: .caption
        }
    }
    
    static func color(for role: TextRole, palette: ScreenStylePalette) -> Color {
        switch role {
            case .header, .section, .title3, .body, .tile, .largeTitle, .label:
                return palette.text
                
            case .secondary, .caption, .placeholder:
                // Calculate secondary text color based on primary theme text color.
                return palette.text.opacity(0.72)
                
            case .action:
                // Actions (buttons) often use white/light text for contrast against a filled background.
                return .white
        }
    }
}

// MARK: - Legacy / Utility Colors (Cleaned up)
extension Color {
    // New utility color for actions where white might be too harsh
    static let intText = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5

}


//// MARK: - Theme Manager
//@MainActor
//final class ThemeManager: ObservableObject {
//    @AppStorage("selectedColorTheme") private var colorRaw: String = AppColorTheme.default.rawValue
//    @AppStorage("selectedFontTheme")  private var fontRaw: String = AppFontTheme.serif.rawValue
//    
//    @Published var colorTheme: AppColorTheme { didSet { colorRaw = colorTheme.rawValue } }
//    @Published var fontTheme: AppFontTheme { didSet { fontRaw  = fontTheme.rawValue  } }
//    
//    init() {
//        let storedColor = UserDefaults.standard.string(forKey: "selectedColorTheme") ?? AppColorTheme.default.rawValue
//        let storedFont  = UserDefaults.standard.string(forKey: "selectedFontTheme")  ?? AppFontTheme.serif.rawValue
//        self.colorTheme = AppColorTheme(rawValue: storedColor) ?? .default
//        self.fontTheme  = AppFontTheme(rawValue: storedFont)  ?? .serif
//    }
//    
//    func palette(for screen: ScreenName) -> ScreenStylePalette {
//        colorTheme.colors(for: screen)
//    }
//    
//    func styledText(_ content: String, as role: TextRole, in screen: ScreenName) -> Text {
//        let font  = fontTheme.toFont(Self.fontStyle(for: role))
//        let color = Self.color(for: role, palette: palette(for: screen))
//        let weight: Font.Weight = switch role {
//        case .largeTitle:   .bold
//        case .header:       .semibold
//        case .section:      .semibold
//        case .title3:       .semibold
//        case .label:        .medium
//        case .action:       .semibold
//        default:            .regular
//        }
//        
//        return Text(content).font(font).fontWeight(weight).foregroundColor(color)
//    }
//    
//    // MARK: Style mapping
//    static func fontStyle(for role: TextRole) -> Font.TextStyle {
//        switch role {
//        case .largeTitle:   .largeTitle
//        case .header:       .largeTitle
//        case .section:      .title2
//        case .title3:       .title3
//        case .label:        .headline
//        case .action:       .headline
//        case .body:         .body
//        case .tile:         .body
//        case .secondary:    .subheadline
//        case .placeholder:  .subheadline
//        case .caption:      .caption
//        }
//    }
//    
//    static func color(for role: TextRole, palette: ScreenStylePalette) -> Color {
//        switch role {
//        case .header, .section, .title3, .body, .tile, .largeTitle:
//            return palette.text
//        case .secondary, .caption, .placeholder:
//            return textSecondary
//        case .label:
//            return palette.text
//        case .action:
//            // ButtonStyles typically color the label; this keeps Action readable elsewhere.
//            return .intText
//        }
//    }
//}
//
//// MARK: - defines consistent, app-wide color of button text
//extension Color {
//    static let intText = Color(red: 0.96, green: 0.96, blue: 0.96)     // #F5F5F5
//    static let btnTextLight = intText     // #F5F5F5
//    static let btnTextDark = Color(red: 0.99, green: 0.99, blue: 0.99)     // #FDFDFD
//    static let orgOverlayLight = Color(red: 0.9137, green: 0.8627, blue: 0.7373) // #e9dcbc
//    static let orgOverlayDark = Color(red: 0.2588, green: 0.2078, blue: 0.0863) // #423516
//}
//

