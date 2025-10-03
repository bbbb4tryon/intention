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
    
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(p.primary)
            
            // Top Row: the number (scales, doesn't wrap)
            T(value, .title3)
                .statNumberStyle(p)
            T(caption, .caption)
                .statCaptionStyle(p)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption) \(value)")
    }
}
