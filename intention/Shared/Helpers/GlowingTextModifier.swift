//
//  GlowingTextModifier.swift
//  intention
//
//  Created by Benjamin Tryon on 8/26/25.
//
import SwiftUI

struct PulsingBorderModifier: ViewModifier {
    @State private var pulse: Bool = false
    let isSelected: Bool                    // Uses a binding to determine if the button is active
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Capsule().fill(Color.purple)) // The main fill remains purple
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : (pulse ? Color.purple.opacity(0.8) : Color.purple.opacity(0.4)), /// Pulsing effect for notActive
                        lineWidth: isSelected ? 0 : (pulse ? 4 : 2)     /// Pulse
                    )
                    .shadow(
                        color: isSelected ? Color.clear : (pulse ? Color.purple.opacity(0.7) : Color.purple.opacity(0.2)),
                        radius: isSelected ? 0 : (pulse ? 10 : 5),
                        x: 0, y: 0
                    )
            )
            .animation(
                isSelected ? .none : .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                if !isSelected {
                    pulse = true
                }
            }
            .onChange(of: isSelected) { newValue in
                if !newValue {
                    pulse = true
                } else {
                    pulse = false
                }
            }
    }
}

extension View {
    func notActivePulsingEffect(isSelected: Bool) -> some View {
        self.modifier(PulsingBorderModifier(isSelected: isSelected))
    }
}
