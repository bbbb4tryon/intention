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
    
    private let sheetBG = Color(red:0.882, green:0.937, blue:0.702 )
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // behind the card background
            p.background
                .ignoresSafeArea()
            
            Image("Noise64")
                .resizable()
                .scaledToFit()
                .opacity(0.04)
                .blendMode(.overlay)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            
            // MARK: - Sheet container
            VStack(spacing: 0) {
                // Close
                HStack {
                    Capsule()
                        .frame(width: 40, height: 15)
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
                    // p.text is now the Light color (F8F6FA)
                    .foregroundStyle(p.text)
                    .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    // p.surfaces is now the Dark color (1A161E)
                                        .fill(p.surfaces)
                                )
                    .padding(.horizontal, 16)
//                    .background(.clear)
            }
            // keep container clear to see ZStack
            .background(.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            // softened lift, then contact shadow
//            .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 14)
//            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 1)
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
//        .tint(p.accent)
        .environment(\.colorScheme, .light)
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
