//
//  Button+Style.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.

import SwiftUI
// Visual consistency

//private extension ButtonStyle {
//    var foregroundColor: Color { }
//}
struct ButtonConfig_Style: ButtonStyle {
    @EnvironmentObject var theme: ThemeManager
    var screen: ScreenName
    var isMain: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        let palette = theme.palette(for: screen)
        let color = isMain ? palette.accent : palette.primary
        
        return configuration.label
            .font(theme.fontTheme.toFont(.headline))
            .padding()
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

extension Button {
    func mainActionStyle(screen: ScreenName) -> some View {
        self.buttonStyle(ButtonConfig_Style(screen: screen, isMain: true))
    }
    
    func notMainActionStyle(screen: ScreenName) -> some View {
        self.buttonStyle(ButtonConfig_Style(screen: screen, isMain: false))
    }
}
