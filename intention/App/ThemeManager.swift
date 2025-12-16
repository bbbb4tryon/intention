//
//  AppThemeManager.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//
import SwiftUI
import UIKit
// views will use local color constants for validation, border, and secondary text
// Shim: keep code compiling that expects ThemePalette, if any still refer to it!

typealias ThemePalette = ScreenStylePalette

// -- Use a material background (which applies a subtle blur/opacity)
//    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
// modern approach in Swift for non-shadow readability.
// It automatically ensures the text's background contrasts with the content behind it, boosting legibility without adding an explicit shadow
// MARK: Screens
enum ScreenName {
    case focus, history, settings, recalibrate, membership
    //    case focus, history, settings, organizer, recalibrate, membership
}
// MARK: Text roles
enum TextRole {
    case largeTitle, header, section, title3, label, body, tile, secondary, caption, action, placeholder
}

// MARK: - Loader with fallbacks (safe)
private extension Color {
//    static func app(_ name: String, fallback: Color, bundle: Bundle = .main) -> Color {
//        // Prefer the color asset if it exists
//        let trait = UITraitCollection.current
//        if let ui = UIColor(named: name, in: bundle, compatibleWith: trait) {
//            return Color(uiColor: ui)
//        } else {
//            #if DEBUG
//            print("[Theme] Missing color asset '\(name)'. Using fallback.")
//            #endif
//            return fallback
//        }
//    }
    
    static func app(_ name: String, fallback: Color, bundle: Bundle = .main) -> Color {
#if DEBUG
        if bundle.path(forResource: name, ofType: nil) == nil {
            print("[Theme] Missing color assed '\(name)'. Using ballback.")
            return fallback
        }
        #endif
        return Color(name, bundle: bundle)
    }
}


// MARK: - ScreenStylePalette
//Per-screen color tokens
struct ScreenStylePalette {
    let primary: Color          // secondary button bg or highlighting
    let background: Color       // main pages
    let surfaces: Color          // card color, tab bars, // RENAME
    let accent: Color          // CTA color - use for fill
    let text: Color
    
    struct LinearGradientSpecial {
        let colors: [Color]
        let start: UnitPoint
        let end: UnitPoint
    }
    let gradientBackground: LinearGradientSpecial?      // nil == use `background` color
    
    // specifically for ErrorOverlay
    struct RadialGradientSpecial {
        let colors: [Color]
        let center: UnitPoint
        let startRadius: CGFloat
        let endRadius: CGFloat
    }
    // Uses Color.black for guaranteed darkness/contrast
    let radialBackground: RadialGradientSpecial = .init(
        colors: [
            Color.black.opacity(0.8), // Inner (visible, near black)
            Color.black.opacity(0.4), // Middle blend
            Color.clear             // Outer (faded)
        ],
        center: .center,
        startRadius: 0, // Starts at the center
        endRadius: 500 // Adjust this value to control the fade distance
    )
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

// MARK: Color Constants
// Theme Name,Background Feel,Primary Text,Vibrant Accent
// Pale Apricot,"Warm, Soft, Encouraging",Deep Umber (#4A3B1C),Electric Blue (#007AFF)
// Sea,"Cool, Crisp, Professional",Deep Teal (#1C3B4A),Vibrant Citron (#B5C808)
// Dusk,"Subtle, Clean, Elegant",Very Dark Plum (#1A161E),Deep Rose (#C83264)
// Primary Background: Pale Apricot (FBF6F3) - Soft & Encouraging

// MARK: - DefaultColors (Assets are the truth)
//private enum DefaultColors {
//    // Apricot FBF6F3
//    static let backgroundLight = Color(red: 0.984, green: 0.965, blue: 0.953)
//    
//    // Surfaces/Card: Slightly darker Apricot (F4EDE9) - Subtle Warm Depth
//    static let surfaces = Color(red: 0.957, green: 0.929, blue: 0.914)
//    
//    // Accent: Electric Blue (007AFF) - High-impact CTA
//    static let accent = Color(red: 0.000, green: 0.480, blue: 1.000)
//    
//    // Deep Umber (4A3B1C) - High contrast & Warm
//    static let text = Color(red: 0.290, green: 0.231, blue: 0.110)
//    
//    // Dark Text/Surface (Recalibrate): Same as text for consistency
//    static let topDark = text // #4A3B1C
//    // Recalibrate bottom light: Matches background for clean transition
//    static let bottomLight = backgroundLight // #FBF6F3
//}

//// New Primary Background: Pale Dusk Gray (F8F6FA) - Subtle & Clean
private enum DefaultColors {
    
    static let backgroundLight = Color.app("AppBackground",
                                           fallback: Color(red: 0.973, green: 0.965, blue: 0.980)) // F8F6FA -> dark would be 3B2F4E
        .opacity(1) // no-op; forces load
   static let surfaces        = Color.app("AppSurfaces",
                                       fallback: Color(red: 0.937, green: 0.922, blue: 0.953)) // EFEBF3 
    static let accent          = Color.app("AppAccent",
                                       fallback: Color(red: 0.784, green: 0.196, blue: 0.392)) // C83264)
    static let text            = Color.app("AppText",
                                       fallback: Color(red: 0.102, green: 0.086, blue: 0.118)) // 1A161E 48284D
    
    // Fallbacks for previews / missing assets
    // (used only if the asset is absent in a preview-only context)
//    static let _fallbackBackground = Color(red: 0.973, green: 0.965, blue: 0.980) // F8F6FA
//    static let _fallbackSurfaces    = Color(red: 0.937, green: 0.922, blue: 0.953) // EFEBF3
//    static let _fallbackAccent     = Color(red: 0.784, green: 0.196, blue: 0.392) // C83264
//    static let _fallbackText       = Color(red: 0.102, green: 0.086, blue: 0.118) // 1A161E
    static let _topDark = text // Dark Text/Surface (Recalibrate): Same as text for consistency
    static let bottomLight = backgroundLight // Recalibrate bottom light: Matches new background for clean transition
//    static let backgroundLight = Color(red: 0.973, green: 0.965, blue: 0.980)
//
//    // New Surface/Card: Slightly darker Dusk Gray (EFEBF3) - Elegant Depth
//    static let surface = Color(red: 0.937, green: 0.922, blue: 0.953)
//
//    // New Accent: Deep Rose (C83264) - Vibrant CTA
//    static let accent = Color(red: 0.784, green: 0.196, blue: 0.392)
//
//    // Text: Very Dark Plum (1A161E) - Highest contrast
//    static let text = Color(red: 0.102, green: 0.086, blue: 0.118)
//
//    // Dark Text/Surface (Recalibrate): Same as text for consistency
//    static let topDark = text // #1A161E
//    // Recalibrate bottom light: Matches new background for clean transition
//    static let bottomLight = backgroundLight // #F8F6FA
}

// Primary Background: Pale Blue-Gray (F3F6F9) - Crisp & Calm
private enum SeaDefaultColors {
    static let backgroundLight = Color(red: 0.953, green: 0.965, blue: 0.976)
    
    // Surface/Card: Slightly darker Blue-Gray (E7ECF1) - Subtle Cool Depth
    static let surfaces = Color(red: 0.906, green: 0.925, blue: 0.945)
    
    // Accent: Vibrant Citron (B5C808) - Engaging CTA
    static let accent = Color(red: 0.710, green: 0.784, blue: 0.031)
    
    // Text: Deep Teal/Navy (1C3B4A) - High contrast & Professional
    static let text = Color(red: 0.110, green: 0.231, blue: 0.290)
    
    // Dark Text/Surface (Recalibrate): Same as text for consistency
    static let topDark = text // #1C3B4A
    // Recalibrate bottom light: Matches new background for clean transition
    static let bottomLight = backgroundLight // #F3F6F9
    
    // Define a gradient for the theme
    static let gradient: ScreenStylePalette.LinearGradientSpecial = .init(
        colors: [
            // Darker blue for the top for depth
            Color(red: 0.15, green: 0.35, blue: 0.45), // Dark Teal
            Color(red: 0.3, green: 0.5, blue: 0.6),    // Middle Blue
            backgroundLight                          // Light base
        ],
        start: .top,
        end: .bottom
    )
}

//
//
//// MARK: OrganizerOverlay
//private enum OrgBG {
//    // TopLight and BottomDark are now assigned based on the new backgroundMedium color if needed
//    static let topLight = DefaultColors.backgroundLight
//    static let middleLight = DefaultColors.backgroundMiddle
//    static let bottomDark = DefaultColors.backgroundMedium
//}

// MARK: Recalibrate Sheet
private enum RecalibrateBG {
    static let gradient: ScreenStylePalette.LinearGradientSpecial = .init(
        colors: [
            DefaultColors.text.opacity(0.92),   // top: very dark, better contrast
            DefaultColors.text.opacity(0.66),   // soften banding
            DefaultColors.backgroundLight       // bottom: page bg
        ],
        start: .top, end: .bottom
    )
    static let bottomLight = DefaultColors.backgroundLight
}
// MARK: Membership Sheet
private enum MembershipBG {
    static let gradient: ScreenStylePalette.LinearGradientSpecial = .init(
        colors: [
            DefaultColors.accent.opacity(0.92),
            DefaultColors.accent.opacity(0.75),
            DefaultColors.surfaces                 // calmer base for legibility
        ],
        start: .topLeading, end: .bottomTrailing
    )
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
    
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch self {
        case .default:
            switch screen {
            case .focus, .history, .settings:
                return .init(
                    primary: DefaultColors.surfaces,             // secondary/quiet CTAs
                    background: DefaultColors.backgroundLight,    // Page BG
                    surfaces: DefaultColors.surfaces.opacity(0.85), // card/surface (slightly lighter)
                    accent: DefaultColors.accent,                  // CTA color (citron)
                    text: DefaultColors.text,                   // primary text color (dark gray)
                    gradientBackground: nil
                )
                
            case .recalibrate:
                return .init(
                    primary: DefaultColors.text,
                            background: RecalibrateBG.bottomLight,
                            surfaces: DefaultColors.surfaces.opacity(0.12),
                            accent: DefaultColors.accent,
                            text: Color.white,                        // over dark gradient top
                            gradientBackground: RecalibrateBG.gradient
                    )
                
            case .membership:
                return .init(
                    primary: DefaultColors.accent,
                       background: DefaultColors.backgroundLight,
                       surfaces: DefaultColors.surfaces.opacity(0.96),
                       accent: DefaultColors.accent,
                       text: DefaultColors.text,                 // content mostly on light tones
                       gradientBackground: MembershipBG.gradient
                )
                //
                //            case .organizer:
                //                // superior contrast (6.1:1) against the light gradient
                //                /*#7b6428*/ let organizerText = Color(red: 0.4824, green: 0.3922, blue: 0.1569)
                //                return .init(
                //                    primary: DefaultColors.accent,               // CTA color (citron)
                //                    background: .clear,                         // clear, to see gradient
                //                    surface: .clear,                            // let gradient breath
                //                    accent: organizerText,                      // toolbar tint (X button, etc)
                //                    text: organizerText,          // primary text
                //                    gradientBackground: .init(
                //                        colors: [OrgBG.topLight, OrgBG.bottomDark],
                //                        start: .topLeading,
                //                        end: .bottomTrailing // ↖️ Diagonal flow
                //                    )
                //                )
            }
            
            // MARK: - Sea
        case .sea:
            switch screen {
            case .focus, .history, .settings:
                return .init(
                    primary: SeaDefaultColors.surfaces, // Using Surface as primary (e.g., secondary button)
                    background: SeaDefaultColors.backgroundLight, // Using the dark base color for solid BG
                    surfaces: SeaDefaultColors.surfaces.opacity(0.85), // Frosted surface card
                    accent: SeaDefaultColors.accent,
                    text: SeaDefaultColors.text,
                    gradientBackground: nil
                )
                
            case .recalibrate:
                // Unique Gradient Direction: Diagonal
                return .init(
                    primary: SeaDefaultColors.topDark, // Dark primary tint (deep teal)
                    background: SeaDefaultColors.bottomLight, // Light solid fallback
                    surfaces: SeaDefaultColors.surfaces.opacity(0.15), // Frosted cards
                    accent: SeaDefaultColors.accent,
                    text: SeaDefaultColors.text,            // light text color (light background) for contrast over the dark top of gradient
                    gradientBackground: SeaDefaultColors.gradient // Sea Theme Recalibrate Gradient (Defined in SeaDefaultColors)
                )
                
            case .membership:
                // Unique Gradient Direction: Horizontal
                // Uses the Sea theme's specific gradient and colors
                return .init(
                    primary: SeaDefaultColors.surfaces,
                    background: SeaDefaultColors.backgroundLight, // Dark solid fallback
                    surfaces: SeaDefaultColors.surfaces.opacity(0.85),
                    accent: SeaDefaultColors.accent,
                    text: SeaDefaultColors.text,
                    // Reusing Sea's defined gradient but changing direction for variety
                                        gradientBackground: .init(
                                            colors: SeaDefaultColors.gradient.colors,
                                            start: .leading,
                                            end: .trailing // ➡️ Horizontal flow
                                        )
                )
                //
                //            case .organizer:
                //                // Unique Gradient Direction: Vertical
                //                    return .init(
                //                        primary: SeaDefaultColors.surface,
                //                        background: .clear, // clear, to see gradient through FocusShell
                //                        surface: SeaDefaultColors.surfaces.opacity(0.12),
                //                        accent: SeaDefaultColors.accent,
                //                        text: SeaDefaultColors.text,
                //                        gradientBackground: .init(
                //                            colors: seaGradientColors,
                //                            start: .top,
                //                            end: .bottom // ⬇️ Vertical flow
                //                        )
                //                        )
            }
        }
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
//    /// Makes palettes dynamically choose light or dark, depending on system
//
    
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
//        colorTheme.colors(for: screen
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
        case .label:        .semibold
        case .action:       .semibold
        case .tile:         .medium         // .medium improves tile text on light chips
        default: .regular
        }
        return Text(content).font(font).fontWeight(weight).foregroundColor(color)
    }

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
        case .secondary, .caption:
            return palette.text.opacity(0.80)
            
        case .placeholder:
            return palette.text.opacity(0.70)
        case .action:
            // Actions (buttons) often use white/light text for contrast against a filled background.
            return .white
        }
    }
}

// MARK: - ThemeSwatches
struct ThemeSwatches: View {
    var body: some View {
        let bg = DefaultColors.backgroundLight
        let sf = DefaultColors.surfaces
        let ac = DefaultColors.accent
        let tx = DefaultColors.text
        HStack(spacing: 12) {
            ForEach([("BG", bg), ("SF", sf), ("AC", ac), ("TX", tx)], id:\.0) { label, c in
                VStack {
                    Circle().fill(c).frame(width: 44, height: 44)
                    Text(label).font(.caption)
                }
            }
        }
        .padding().background(bg).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: Bridge
// Global app-wide background bridge for App entry / UIKit surfaces.
extension ThemeManager {
    static var appBackgroundColor: Color {
        // Use the asset; it auto-adapts to Light/Dark
        Color("AppBackground")
    }
}

// MARK: - Legacy / Utility Colors (Cleaned up)
extension Color {
    // New utility color for actions where white might be too harsh
    static let intText = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5
}
