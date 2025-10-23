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
            dot(label: "Left Foot", isActive: activeIndex == 0)
            dot(label: "Right Foot", isActive: activeIndex == 1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(activeIndex == 0 ? "Left foot" : "Right foot")
    }

    let fWOn: CGFloat = 50
    let fWOff: CGFloat = 10
    let fHOn: CGFloat = 50
    let fHOff: CGFloat = 10
    private func dot(label: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? p.accent : p.border)
                .frame(width: isActive ? fWOn : fWOff, height: isActive ? fHOn : fHOff)
                .overlay(Circle().stroke(p.border, lineWidth: isActive ? 0 : 1))
                .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isActive)
            Text(label)
                .font(.callout.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? p.text : p.textSecondary)
        }
    }
}
