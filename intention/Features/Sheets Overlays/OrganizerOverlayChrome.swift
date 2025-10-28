//
//  OrganizerOverlayChrome.swift
//  intention
//
//  Created by Benjamin Tryon on 10/21/25.
//

import SwiftUI

/// A full-screen wrapper that *looks* like a sheet: rounded top, grabber, swipe down to dismiss.
struct OrganizerOverlayChrome<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    var onClose: () -> Void
    @ViewBuilder var content: Content
    
    @State private var offsetY: CGFloat = 0
    private let dismissThreshold: CGFloat = 120
    private var p: ScreenStylePalette { theme.palette(for: .organizer) }
    
    var body: some View {
        ZStack {
            // The themed gradient or fallback background
            if let g = p.gradientBackground {
                LinearGradient(colors: g.colors, startPoint: g.start, endPoint: g.end)
                    .ignoresSafeArea()
                    .texturedGradient(strength: 0.05, animate: false)       // subtle, static
            } else {
                p.background.ignoresSafeArea()
            }
            
            // "Sheet" container
            VStack(spacing: 0) {
                // Grabber + close
                HStack {
                    Capsule().frame(width: 40, height: 5).opacity(0.35)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity) //FIXME: - if alignment is off, enter , .alignment: .something)
                        .overlay(alignment: .trailing) {
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.headline)
                                    .padding(12)
                            }
////                            .tint(p.accent)
//                            .tint()
                        }
                }
                .contentShape(Rectangle())

                // -- Rounded part of sheet content --
                // OrganizerOverlayScreen content is here
                content
                    .background(.clear) // Ensures content itself doesn't hide the ZStack gradient
            }
            .clipShape(.rect(cornerRadius: 22, style: .continuous))
            .offset(y: max(0, offsetY))
            .gesture(
                DragGesture()
                    .onChanged { offsetY = max(0, $0.translation.height) }
                    .onEnded { final in
                        if final.translation.height > dismissThreshold { onClose() }
                        else { withAnimation(.spring) { offsetY = 0 }}
                    }
            )
            .padding(.top, 8)
            .padding(.horizontal, 0)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
