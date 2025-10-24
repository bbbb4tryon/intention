//
//  Text+StatStyles.swift
//  intention
//
//  Created by Benjamin Tryon on 10/3/25.
//

import SwiftUI

struct StatNumberStyle: ViewModifier {
    let p: ScreenStylePalette
    
    func body(content: Content) -> some View {
        content
            .bold()
            .monospacedDigit()
            .lineLimit(1)                           // never wrap
            .minimumScaleFactor(0.6)                // shrink, instead
            .allowsTightening(true)
            .foregroundStyle(p.text)
            .layoutPriority(2)
    }
}
struct StatCaptionStyle: ViewModifier {
//    let p: ScreenStylePalette
    private let textSecondary = Color.intCharcoal.opacity(0.85)
    func body(content: Content) -> some View {
        content
            .lineLimit(1)                           // never wrap
            .minimumScaleFactor(0.6)                // shrink, instead
            .allowsTightening(true)
            .foregroundStyle(textSecondary)
            .layoutPriority(1)
    }
}
extension View {
    func statNumberStyle(_ p: ScreenStylePalette) -> some View { modifier(StatNumberStyle(p:p)) }
//    func statCaptionStyle(_ p: ScreenStylePalette) -> some View { modifier(StatCaptionStyle(p:p)) }
    func statCaptionStyle(_ p: ScreenStylePalette) -> some View { modifier(StatCaptionStyle()) }
}
