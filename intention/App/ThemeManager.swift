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
    case focus, history, settings, recalibrate, membership
    //    case focus, history, settings, organizer, recalibrate, membership
}
// MARK: Text roles
enum TextRole {
    case largeTitle, header, section, title3, label, body, tile, secondary, caption, action, placeholder
}

// MARK: - Loader with fallbacks (safe)
private extension Color {
    
    static func app(_ name: String, fallback: Color, bundle: Bundle = .main) -> Color {
        // Compiled color assets aren’t files; just resolve directly.
        // If the asset truly doesn’t exist, this will still gracefully resolve at runtime.
        Color(name, bundle: bundle)
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
//            Color.black.opacity(0.6), // Inner (visible, near black)
//            Color.black.opacity(0.3), // Middle blend
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


//// New Primary Background: Pale Dusk Gray (F8F6FA) - Subtle & Clean
private enum DefaultColors {
    
    static let backgroundLight = Color.app("AppBackground",
                                           fallback: Color(red: 0.557, green: 0.698, blue: 0.557)) // F8F6FA -> dark would be 3B2F4E
        .opacity(1) // no-op; forces load
   static let surfaces        = Color.app("AppSurfaces",
                                          fallback: Color(red: 0.851, green: 0.910, blue: 0.651)) // EFEBF3
    static let accent          = Color.app("AppAccent",
                                           fallback: Color(red: 0.518, green: 0.000, blue: 0.714)) // C83264)
    static let text            = Color.app("AppText",
                                       fallback: Color(red: 0.239, green: 0.314, blue: 0.000)) // 1A161E 48284D

    static let _topDark = text // Dark Text/Surface (Recalibrate): Same as text for consistency
    static let bottomLight = backgroundLight // Recalibrate bottom light: Matches new background for clean transition
    static let recalibrateFixedBG =  Color(red:0.882, green:0.937, blue:0.702 )
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


// MARK: Recalibrate Sheet
private enum RecalibrateBG {
    static let gradient: ScreenStylePalette.LinearGradientSpecial = .init(
        colors: [
            DefaultColors.surfaces.opacity(0.85),
            DefaultColors.surfaces.opacity(0.45)
        ],
        start: .top, end: .bottom
    )
    static let bottomLight = DefaultColors.backgroundLight
}
// MARK: Membership Sheet
private enum MembershipBG {
    static let gradient: ScreenStylePalette.LinearGradientSpecial = .init(
        colors: [
            DefaultColors.surfaces.opacity(0.85),
            DefaultColors.surfaces.opacity(0.45)
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
                    primary: DefaultColors.text,            // The "Primary" identity is now the dark color
                    background: DefaultColors.backgroundLight,  // The "Sheet" behind the card is still light
                    surfaces: DefaultColors.surfaces,           // Flip: The card itself is now Dark
                    accent: DefaultColors.accent,
                    text: DefaultColors.backgroundLight,    // Flip: Text on the dark card is now Light
                    gradientBackground: nil
                    )
                
            case .membership:
                return .init(
                    primary: DefaultColors.accent,
                       background: DefaultColors.backgroundLight,
                       surfaces: DefaultColors.surfaces.opacity(0.96),
                       accent: DefaultColors.accent,
                       text: DefaultColors.text,                 
                       gradientBackground: nil
                )
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
    
//    static let intGreen = Color("intGreen")   
}
