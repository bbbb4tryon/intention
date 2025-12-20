//
//  StatPill.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

struct StatPill: View {
    @EnvironmentObject var theme: ThemeManager
    
    let icon: String
    let value: String
    let caption: String
    let screen: ScreenName
    
    // Theme Hooks
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // MARK: - Computed properties
        private var iconGradient:
    LinearGradient {
        LinearGradient(colors: [Color.intGreen, Color.appText.opacity(0.9)],
                       startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    private var iconView: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(iconGradient)
            .frame(height: 24)
    }
    
    private var numberView: some View {
        T(value, .title3)
            .statNumberStyle(p)
            .frame(height: 22)
    }
    
    private var captionView: some View {
        T(caption, .caption)
            .statCaptionStyle(p)
            .frame(height: 16)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Green as icon tint - subtle brand presence
            iconView
            
            // Top Row: the number (scales, doesn't wrap)
            numberView
            captionView
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption) \(value)")
    }
}
