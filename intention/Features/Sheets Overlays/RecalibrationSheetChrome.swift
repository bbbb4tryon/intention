//
//  RecalibrationSheetChrome.swift
//  intention
//
//  Created by Benjamin Tryon on 10/13/25.
//

import SwiftUI

struct RecalibrationSheetChrome<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager

    var onClose: () -> Void
    @ViewBuilder var content: Content
    
    @State private var offsetY: CGFloat = 0
    private let dismissThreshold: CGFloat = 120
    
    private var p: ScreenStylePalette { theme.palette(for: .recalibrate) }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            
            // recalibrate palette base gradient
            BackplateGradient(p: p)
                .ignoresSafeArea()
            
            // MARK: Textured background begins
            Group {
                RadialGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.38), Color.black.opacity(0.12), .clear]),
                    center: .center, startRadius: 0, endRadius: 520
                )
                .blendMode(.multiply)
                .ignoresSafeArea()
                
                Image("Noise64")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.035)
                    .blendMode(.overlay)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
            
            // MARK: - Sheet container
            VStack(spacing: 0) {
                // Close
                HStack {
                    Capsule()
                        .frame(width: 40, height: 5)
                        .opacity(0.35)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .overlay(alignment: .trailing) {
                            Button(action: onClose) {
                                Image(systemName: "x.square")
                                    .symbolRenderingMode(.hierarchical)
                                    .imageScale(.large)
                                    .font(.title3.weight(.semibold))
                                    .contentShape(Rectangle())
                            }
                            .tint(p.accent)
                        }
                }
                .contentShape(Rectangle())
                
                // Internal content
                content
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(p.text.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(radius: 12, y: 6)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .background(.clear)
            }
            // keep container clear to see ZStack
            .background(.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            // softened lift, then contact shadow
            .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 14)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 1)
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
        .tint(p.accent)
    }
}

#if DEBUG
#Preview("Chrome") {
    RecalibrationSheetChrome(onClose: {}) {
        VStack(spacing: 12) {
            Text("Recalibrate Content")
            Button("Primary", action: {})
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}
#endif
