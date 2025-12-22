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
    
    // MARK: - Computed properties
    // -- Style --
    private func isActive(_ i: Int) -> Bool {
        i == activeIndex
    }
    
    private func phaseFont(_ i: Int) -> Font {
        .footnote.weight(isActive(i) ? .semibold : .regular)
    }
    
    private func phaseForeground(_ i: Int) -> Color {
        isActive(i) ? p.text : textSecondary
    }
    
    private func phaseBackground(_ i: Int) -> some ShapeStyle {
        isActive(i) ? p.accent.opacity(0.16) : Color.clear
    }
    
    private func phaseStroke(_ i: Int) -> Color {
        isActive(i) ? p.accent : colorBorder
    }
    
    private func phaseScale(_ i: Int) -> CGFloat {
        isActive(i) ? 1.1 : 1.0
    }
    
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
                        Capsule().fill(i == activeIndex ? p.accent.opacity(0.16) : .clear)
                    )
                    .overlay(
                        Capsule().stroke(i == activeIndex ? p.accent : colorBorder, lineWidth: 1)
                    )
                    .foregroundStyle(i == activeIndex ? p.text : textSecondary)
                    .scaleEffect(i == activeIndex ? 1.1 : 1.0)
                    .animation(.spring(response: 0.22, value: activeIndex))
                
                // MARK: Active phase dot
                Circle()
                        .fill(i == activeIndex ? Color.intGreen : .clear)
                    .frame(width: 8, height: 8)
                    .opacity(i == activeIndex ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
                    .accessibilityLabel("\(phases[i])\(i == activeIndex ? ", current" : "")")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        // thin container stroke
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(p.text.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
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
