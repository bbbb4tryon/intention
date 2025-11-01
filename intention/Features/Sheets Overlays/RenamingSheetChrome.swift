//
//  RenamingSheetChrome.swift
//  intention
//
//  Created by Benjamin Tryon on 10/29/25.
//

import SwiftUI

struct RenamingSheetChrome<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    var onClose: () -> Void
    @ViewBuilder var content: Content

    @State private var offsetY: CGFloat = 0
    private let dismissThreshold: CGFloat = 120
    // You can route this to .organizer or .settings; choose the one that gives best contrast there
    private var p: ScreenStylePalette { theme.palette(for: .history) }

    var body: some View {
        ZStack {
            if let g = p.gradientBackground {
                LinearGradient(colors: g.colors, startPoint: g.start, endPoint: g.end).ignoresSafeArea()
            } else {
                p.background.ignoresSafeArea()
            }
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

                content
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            .clipShape(.rect(cornerRadius: 22, style: .continuous))
            .offset(y: max(0, offsetY))
            .gesture(
                DragGesture()
                    .onChanged { offsetY = max(0, $0.translation.height) }
                    .onEnded { final in
                        if final.translation.height > dismissThreshold { onClose() }
                        else { withAnimation(.spring) { offsetY = 0 } }
                    }
            )
            .padding(.top, 8)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#if DEBUG
#Preview("Chrome") {
    RenamingSheetChrome(onClose: {}) {
        VStack(spacing: 12) {
            Text("rename Content")
            Button("Primary", action: {})
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}
#endif
