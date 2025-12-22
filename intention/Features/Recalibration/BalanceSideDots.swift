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
    
    private let fWOn:  CGFloat = 18
    private let fWOff: CGFloat = 8
    private let fHOn:  CGFloat = 18
    private let fHOff: CGFloat = 8
    
    private let screen: ScreenName = .recalibrate
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    
    var body: some View {
        T("Current side", .caption)
            .foregroundStyle(p.text.opacity(0.7))
            .padding(.bottom, 6)
        
        HStack(spacing: 16) {
            dot(label: "Left", isActive: activeIndex == 0)
            dot(label: "Right", isActive: activeIndex == 1)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(activeIndex == 0 ? "Left Leg" : "Right Leg")
    }

    private func dot(label: String, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? p.accent : .clear)
                .frame(
                    width: isActive ? fWOn : fWOff,
                    height: isActive ? fHOn : fHOff)
                .overlay(
                    Circle()
                        .stroke(isActive ? p.accent : colorBorder, lineWidth: 1)
                )
                .animation(.snappy(duration: 0.2), value: isActive)
            
           Text(label)
                .font(.footnote.weight(isActive ? .semibold : .regular))
                    .animation(.snappy(duration: 0.25), value: isActive)

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
