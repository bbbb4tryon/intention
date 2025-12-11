//
//  PulseAura.swift
//  intention
//
//  Created by Benjamin Tryon on 11/3/25.
//

import SwiftUI

/// its own animation driver (TimelineView(.animation)), so the view stays “how,” not “when.”
struct PulseAura: ViewModifier {
    let color: Color
    let isActive: Bool
    
    /// 1.4s “breathing” period to match the design note
    private let period: TimeInterval = 1.4
    //    @State private var thisPulses = 0.0     // formerly t
    
    func body(content: Content) -> some View {
        ZStack {
            if isActive {
                TimelineView(.animation) { ctx in
                    // Smooth, preview-safe time source
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let phase = sin((2 * .pi / period) * t)  // -1...+1
                    Circle()
                        .fill(color.opacity(0.18))
                        .scaleEffect(1.0 + 0.03 * CGFloat(1 + phase)) // ~3% “breath”
                        .blur(radius: 12)
                        .frame(height: 54)
                    //                                       .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: thisPulses)
                    //                                       .onAppear { t = .pi / 2 }
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            content
        }
    }
}

extension View {
    func pulseAura(color: Color, active: Bool) -> some View {
        modifier(PulseAura(color: color, isActive: active))
    }
}
// MARK: - Minimal Demo Views (for Previews only)

private struct PulseButtonDemo: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) private var systemScheme
    @State private var isActive = true
    
    var body: some View {
        let p = theme.palette(for: .focus, scheme: systemScheme)
        
        VStack(spacing: 16) {
            Button("Pulse Aura") { /* no-op */ }
                .frame(maxWidth: .infinity, minHeight: 48)
                .pulseAura(color: p.accent, active: isActive)
                .buttonStyle(.plain) // you’ll likely use your PrimaryActionStyle elsewhere
            
            Toggle("Active", isOn: $isActive)
                .toggleStyle(.switch)
        }
        .padding(20)
        .background(p.background.ignoresSafeArea())
    }
}

// MARK: - Previews
#Preview("Always Active") {
    let theme = ThemeManager()
    
    Button("Pulse Aura") { }
        .frame(maxWidth: .infinity, minHeight: 48)
        .pulseAura(color: theme.palette(for: .focus, scheme: .light).accent, active: true)
        .padding(20)
        .background(theme.palette(for: .focus, scheme: .light).background)
        .environmentObject(theme)
}

#Preview("Interactive Toggle") {
    let theme = ThemeManager()
    
    PulseButtonDemo()
        .environmentObject(theme)
}
