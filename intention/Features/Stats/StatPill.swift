//
//  StatPill.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

struct StatPill: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) private var systemScheme
    let icon: String
    let value: String
    let caption: String
    let screen: ScreenName
    
    private var p: ScreenStylePalette { theme.palette(for: screen, scheme: systemScheme) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen, scheme: systemScheme) } }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(p.primary)
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
