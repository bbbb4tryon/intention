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
    
    var body: some View {
        HStack(spacing: 10){
            ForEach(phases.indices, id: \.self) { i in
                Text(phases[i])
                    .font(.footnote.weight(i == activeIndex ? .semibold : .regular))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        Capsule().fill(i == activeIndex ? p.surface.opacity(0.9) : .clear)
                        )
                    .overlay(
                        Capsule().stroke(i == activeIndex ? p.border : .clear, lineWidth: 1)
                    )
                    .foregroundStyle(i == activeIndex ? p.text : p.textSecondary)
                    .scaleEffect(i == activeIndex ? 1.06 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.85), value: activeIndex)
                    .accessibilityLabel("\(phases[i])\(i == activeIndex ? ", current" : "")")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
