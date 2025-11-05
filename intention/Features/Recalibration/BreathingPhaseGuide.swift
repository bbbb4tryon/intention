//
//  BreathingPhaseGuide.swift
//  intention
//
//  Created by Benjamin Tryon on 9/14/25.
//

import SwiftUI

struct BreathingPhaseGuide: View {
    @EnvironmentObject var theme: ThemeManager
    
    let phases: [String]
    let activeIndex: Int
    let p: ScreenStylePalette
    
    // --- Local Color Definitions by way of Recalibration ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(phases.indices, id: \.self) { i in
                VStack(spacing: 4){
                Text(phases[i])
                    .font(.footnote.weight(i == activeIndex ? .semibold : .regular))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        Capsule().fill(i == activeIndex ? p.surface.opacity(0.90) : .clear)
                    )
                    .overlay(
                        Capsule().stroke(i == activeIndex ? colorBorder : .clear, lineWidth: 1)
                    )
                    .foregroundStyle(i == activeIndex ? p.text : textSecondary)
                    .scaleEffect(i == activeIndex ? 1.06 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.85), value: activeIndex)
                
                // MARK: Active phase dot
                Circle()
                    .fill(i == activeIndex ? p.accent : .clear)
                    .frame(width: 6, height: 6)
                    .opacity(i == activeIndex ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
                    .accessibilityLabel("\(phases[i])\(i == activeIndex ? ", current" : "")")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        // thin accent border around the whole guide
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(p.accent.opacity(0.85), lineWidth: 1)
        )
        .padding(.horizontal, 2)
    }
}


#if DEBUG
#Preview("Breathing Guide") {
    let theme = ThemeManager()
    let pal = theme.palette(for: .recalibrate)
    
    BreathingPhaseGuide(
        phases: ["Inhale", "Hold", "Exhale", "Hold"],
        activeIndex: 0,
        p: pal
    )
    .environmentObject(theme)
}
#endif
