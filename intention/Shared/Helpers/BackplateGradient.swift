//
//  BackplateGradient.swift
//  intention
//
//  Created by Benjamin Tryon on 11/2/25.
//
import SwiftUI

struct BackplateGradient: View {
    let p: ScreenStylePalette
    var body: some View {
        Group {
            if let g = p.gradientBackground {
                LinearGradient(colors: g.colors, startPoint: g.start, endPoint: g.end)
            } else {
                p.background
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func sheetInnerHighlight(cornerRadius: CGFloat = 22) -> some View {
        self
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.18), .clear],
                    startPoint: .top, endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .blendMode(.softLight)
                .allowsHitTesting(false)
            )
    }
}
