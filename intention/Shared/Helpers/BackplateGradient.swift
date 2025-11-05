//
//  BackplateGradient.swift
//  intention
//
//  Created by Benjamin Tryon on 11/2/25.
//
import SwiftUI

struct BackplateGradient: View {
    // drives tiny animation of liveliness
    @State private var tinydrift: CGFloat = 0
    let p: ScreenStylePalette
    
    var body: some View {
        // vertical drive amound ~2%
        let offset = 0.02 * sin(tinydrift)
        
        Group {
            if let g = p.gradientBackground {
                LinearGradient(colors: g.colors,
                               startPoint: UnitPoint(x: g.start.x, y: g.start.y + offset),
                               endPoint: UnitPoint(x: g.end.x, y: g.end.y, + offset)
                               )
            } else {
                p.background
            }
        }
        .ignoresSafeArea()
        .task {
            // maintain static previews
            guard !IS_PREVIEW else { return }
            
            // 30s cycle - very long frequency/time frame
            // auto-cancelled when view disappears
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)     // 0.2s tick
                    .animation(.linear(duration: 0.2)) { timedrift += 0.04 }
            }
        }
        .accessibilityHidden(true)
    }
}
