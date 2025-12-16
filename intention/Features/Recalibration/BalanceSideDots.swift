//
//  BalanceSideDots.swift
//  intention
//
//  Created by Benjamin Tryon on 9/14/25.
//

import SwiftUI

struct BalanceSideDots: View {
    @EnvironmentObject var theme: ThemeManager
    
    let activeIndex: Int   // 0 = Left, 1 = Right
    
    // --- Local Color Definitions by way of Recalibration ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    private let fWOn:  CGFloat = 50
    private let fWOff: CGFloat = 10
    private let fHOn:  CGFloat = 50
    private let fHOff: CGFloat = 10
    
    private let screen: ScreenName = .recalibrate
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        T("On Cue, Lift Your Leg and Balance on the Requisit Leg", .label)
            .padding()
        
        HStack(spacing: 16) {
            dot(label: "Left", isActive: activeIndex == 0)
            dot(label: "Right", isActive: activeIndex == 1)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(activeIndex == 0 ? "Left foot" : "Right foot")
    }

    private func dot(label: String, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? p.accent : colorBorder)
                .frame(
                    width: isActive ? fWOn : fWOff,
                    height: isActive ? fHOn : fHOff)
                .overlay(Circle()
                    .stroke(colorBorder, lineWidth: isActive ? 0 : 1)
                )
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(
                    .spring(response: 0.20, dampingFraction: 0.85), value: isActive)
            
            Text(label)
                .font(.callout.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? p.text : textSecondary)
        }
        .padding(.horizontal, 10)
               .padding(.vertical, 6)
               .background(
                   RoundedRectangle(cornerRadius: 999)
                       .fill(isActive ? p.accent.opacity(0.12) : Color.clear)
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 999)
                       .stroke(isActive ? p.accent : colorBorder,
                               lineWidth: isActive ? 1.5 : 1.0)
               )
               .animation(.spring(response: 0.25, dampingFraction: 0.85),
                          value: isActive)
           }
       }


#if DEBUG
#Preview("Balance Dots") {
    let theme = ThemeManager()
    let pal = theme.palette(for: .recalibrate)
    
    BalanceSideDots(
//        activeIndex: 0, p: pal, screen: ScreenName.recalibrate
        activeIndex: 0
    )
        .environmentObject(theme)
}
#endif
