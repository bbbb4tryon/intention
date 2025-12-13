//
//  MembershipSheetChrome.swift
//  intention
//
//  Created by Benjamin Tryon on 10/29/25.
//

import SwiftUI

/// Full-screen “sheet” wrapper: rounded top, grabber, swipe-to-dismiss.
/// Reuses your per-screen palette for .membership.
struct MembershipSheetChrome<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager

    var onClose: () -> Void
    @ViewBuilder var content: Content

    @State private var offsetY: CGFloat = 0
    private let dismissThreshold: CGFloat = 120
    private var p: ScreenStylePalette { theme.palette(for: .membership) }

    var body: some View {
        ZStack {
            // ^^ ZStack paints the big gradient
            // The themed gradient or fallback background
            BackplateGradient(p: p)
            // Sheet container/body, kept clear for gradient to shine throw
            VStack(spacing: 0) {
                HStack {
                    Capsule().frame(width: 40, height: 5).opacity(0.35)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .trailing) {
                            Button(action: onClose) {
                                Image(systemName: "xmark").font(.headline).padding(12)
                            }
                            .tint(p.accent)
                        }
                }
                .contentShape(Rectangle())

                // Your sheet content
                content
                    // keep inner content transparent
                    .background(.clear)
            }
            // lets ZStack gradient through because container has no fill/ is clear
            .background(.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            // softened lift, then contact shadow
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 18)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 1)

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

#if DEBUG
#Preview("Chrome") {
    MembershipSheetChrome(onClose: {}) {
        VStack(spacing: 12) {
            Text("mem Content")
            Button("Primary", action: {})
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}
#endif
