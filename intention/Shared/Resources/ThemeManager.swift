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
//    dynamic foreground color that automatically adjusts based on the background color.
}

extension ScreenStylePalette.LinearGradientSpecial {
    /// Lightweight sRGB average of the first and last color.
    var averageColor: Color {
        guard let c0 = colors.first, let c1 = colors.last else { return .clear }
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { (a + b) / 2 }
        let (r0,g0,b0,a0) = c0.srgbComponents()
        let (r1,g1,b1,a1) = c1.srgbComponents()
        return Color(.sRGB,
                     red:   Double(mix(r0, r1)),
                     green: Double(mix(g0, g1)),
                     blue:  Double(mix(b0, b1)),
                     opacity: Double(mix(a0, a1)))
    }
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
                    primary: DefaultColors.surface,             // secondary/quiet CTAs
                    background: DefaultColors.backgroundLight,    // Page pg
                    surface: DefaultColors.surface.opacity(0.85), // card/surface (slightly lighter)
                    accent: DefaultColors.accent,                  // CTA color (citron)
                    text: DefaultColors.text,                   // primary text color (dark gray)
                    gradientBackground: nil
                )
                
            case .recalibrate:
                return .init(
                    primary: RecalibrateBG.bottomDark,          // icon tints if needed
                    background: RecalibrateBG.topLight,         // fallback if gradient is nil
                    surface: DefaultColors.surface.opacity(0.10),   // frosted cards
                    accent: DefaultColors.accent,               // CTA on sheet
                    text: DefaultColors.backgroundLight,       // light text over dark blue
                    gradientBackground: .init(
                        colors: [(RecalibrateBG.topLight), (RecalibrateBG.bottomDark)],
                        start: .topLeading,
                        end: .bottomTrailing
                    )
                )
                
            case .membership:
                return .init(
                    primary: DefaultColors.accent,               // CTA color (citron)
                    background: DefaultColors.backgroundLight,    // fallback if gradient is nil
                    surface: DefaultColors.surface.opacity(0.96), // card/surface (slightly lighter)
                    accent: DefaultColors.accent,               // CTA color (citron)
                    text: DefaultColors.text,                   // primary text color (dark gray)
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
                    primary: DefaultColors.accent,               // CTA color (citron)
                    background: .clear,                         // clear, to see gradient
                    surface: .clear,                            // let gradient breath
                    accent: organizerText,                      // toolbar tint (X button, etc)
                    text: organizerText,          // primary text
                    gradientBackground: .init(
                        colors: [OrgBG.topLight, OrgBG.bottomDark],  
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
    /// Returns sRGB components (0...1). Best-effort for dynamic/system colors.
    fileprivate func srgbComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        // Bridge to UIColor; works on iOS targets (your app is iOS-only).
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Fallback for non-RGB colors; convert via CIColor (non-optional)
            let ci = CIColor(color: ui)
            return (ci.red, ci.green, ci.blue, ci.alpha)
        }
        return (r,g,b,a)
    }
    
    /// Relative luminance per WCAG using linearized sRGB
    func relativeLuminance() -> Double {
        let (r, g, b, _) = srgbComponents()
        func lin(_ c: CGFloat) -> Double {
            let d = Double(c)
            return (d <= 0.04045) ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
        }
        let R = lin(r), G = lin(g), B = lin(b)
        return 0.2126*R + 0.7152*G + 0.0722*B
    }
    
    /// Contrast ratio between two colors (>=1 ... 21)
    func contrastRatio(against other: Color) -> Double {
        let L1 = self.relativeLuminance()
        let L2 = other.relativeLuminance()
        let hi = max(L1, L2), lo = min(L1, L2)
        return (hi + 0.05) / (lo + 0.05)
    }
    
    /// Chooses black/white that exceeds target contrast against a background if possible.
    /// Falls back to the provided `preferred` color when already sufficient.
    static func idealForeground(preferred: Color, on background: Color, target: Double = 6.1) -> Color {
        // If preferred already meets target, keep it (respects your theme’s text tone)
        if preferred.contrastRatio(against: background) >= target {
            return preferred
        }
        // Otherwise pick the better of pure black or pure white
        let black = Color.black, white = Color.white
        let cBlack = black.contrastRatio(against: background)
        let cWhite = white.contrastRatio(against: background)
        return (cBlack >= cWhite) ? black : white
        
    }
}

//Color + contrast utilities (safe, sRGB-linear, works with SwiftUI Color)
//
//Color extension to calculate .shadow or .material combination best contrasting with the text color of the specific screen based on the gradient background's luminence; the logic would then be applied to the specific areas behind text
//import SwiftUI
//
//extension Color {
//    func luminance() -> Double {
//        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
//        
//        // Convert SwiftUI Color to UIKit's UIColor to get RGB components
//        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
//            return 0.0
//        }
//        
//        // sRGB to linear RGB conversion
//        let adjustedR = (r < 0.04045) ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
//        let adjustedG = (g < 0.04045) ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
//        let adjustedB = (b < 0.04045) ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)
//        
//        // Calculate luminance (perceived brightness)
//        return 0.2126 * adjustedR + 0.7152 * adjustedG + 0.0722 * adjustedB
//    }
//
//    func contrasted(against color: Color) -> Color {
//        let textLuminance = self.luminance()
//        let backgroundLuminance = color.luminance()
//        let contrastRatio = (max(textLuminance, backgroundLuminance) + 0.05) / (min(textLuminance, backgroundLuminance) + 0.05)
//        
//        // W3C recommendation for enhanced contrast is 7:1 (AAA)
//        // A ratio of 4.5:1 is the minimum (AA)
//        // Adjust the threshold to achieve the desired contrast
//        if contrastRatio < 6.1 {
//            // Not enough contrast, choose a contrasting color
//            return backgroundLuminance > 0.5 ? .black : .white
//        } else {
//            return self
//        }
//    }
//}
//
//In SwiftUI, a texturized gradient background with superior contrast can be created by layering a subtle noise or grain texture over a LinearGradient. The texture helps to break up the smooth gradient, ensuring a more consistent contrast ratio against the text, which is a key accessibility requirement. A contrast ratio of 4.5:1 is the standard for normal text, with 3:1 for larger text, so 6.1:1 offers excellent readability.
//Method 1: Using a noise shader
//This modern technique provides the best performance and flexibility for generating procedural textures.
//1. Create a noise shader
//Create a new Metal file (.metal) in Xcode, for instance NoiseShader.metal, with the following code to generate a simple noise texture.
//
// // NoiseShader.metal
//#include <metal_stdlib>
//using namespace metal;
//
//[[ stitchable ]] half4 noiseShader(float2 position, half4 color, float2 size, float time) {
//    float value = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
//    return half4(value, value, value, 1) * color.a;
//}
//
//2. Define within the AvailabilityTarget+.swift
//
//3. Apply the shader in a SwiftUI view
//You can now apply this shader to your gradient in SwiftUI.
//
// 4. How it works:
//A LinearGradient provides the base light colors.
//The .visualEffect modifier applies the noiseShader using a layerEffect.
//The time parameter can be used to animate the noise, or you can use a fixed value to create a static texture.
//An opaque or translucent background, such as .ultraThinMaterial, can be placed directly behind the text to ensure the contrast ratio remains high in all areas, while still letting the textured background show through.
//
//
//import SwiftUI
//
//struct TexturedGradientView: View {
//    let lightColors: [Color] = [Color(red: 0.95, green: 0.98, blue: 1.0), Color(red: 0.85, green: 0.95, blue: 1.0)]
//
//    var body: some View {
//        ZStack {
//            // Background Layer
//            LinearGradient(
//                colors: lightColors,
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .ignoresSafeArea()
//            .visualEffect { content, proxy in
//                content
//                    .layerEffect(
//                        ShaderLibrary.default.noiseShader(
//                            .boundingRect,
//                            .float(3.0), // Noise strength
//                            .float(proxy.time)
//                        ),
//                        maxSampleOffset: .zero // For static noise
//                    )
//            }
//
//            // Foreground Text
//            VStack {
//                Text("Superior Contrast")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .foregroundColor(.black)
//                Text("6.1:1 Contrast Ratio")
//                    .font(.title)
//                    .foregroundColor(.black.opacity(0.8))
//            }
//            .padding(20)
//            .background(.ultraThinMaterial) // Use material for guaranteed contrast on text
//            .cornerRadius(12)
//        }
//    }
//}
