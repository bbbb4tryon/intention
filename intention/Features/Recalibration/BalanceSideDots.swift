//
//  BalanceSideDots.swift
//  intention
//
//  Created by Benjamin Tryon on 9/14/25.
//

import SwiftUI

struct BalanceSideDots: View {
    let activeIndex: Int   // 0 = Left, 1 = Right
    let p: ScreenStylePalette

    var body: some View {
        HStack(spacing: 16) {
            dot(label: "Left", isActive: activeIndex == 0)
            dot(label: "Right", isActive: activeIndex == 1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(activeIndex == 0 ? "Left foot" : "Right foot")
    }

    private func dot(label: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? p.accent : p.border)
                .frame(width: isActive ? 10 : 8, height: isActive ? 10 : 8)
                .overlay(Circle().stroke(p.border, lineWidth: isActive ? 0 : 1))
                .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isActive)
            Text(label)
                .font(.footnote.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? p.text : p.textSecondary)
        }
    }
}
