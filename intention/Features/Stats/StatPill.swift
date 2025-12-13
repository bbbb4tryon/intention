//
//  StatPill.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

// Company brand color - matches logo/app icon
struct StatPill: View {
    @EnvironmentObject var theme: ThemeManager

    let icon: String
    let value: String
    let caption: String
    let screen: ScreenName
    
    
    // Theme Hooks
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // Local Color Definitions
    private let companyGreen = Color(red: 0.78, green: 0.19, blue: 0.39) // #C73163
    
    var body: some View {
        VStack(spacing: 4) {
            // Company green as icon tint - subtle brand presence
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            companyGreen,
                            companyGreen.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 24)
            
            // Top Row: the number (scales, doesn't wrap)
            T(value, .title3)
                .statNumberStyle(p)
                .frame(height: 22)
            T(caption, .caption)
                .statCaptionStyle(p)
                .frame(height: 16)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption) \(value)")
    }
}
