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
    var color: Color = .intGreen
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

extension Button {
    func mainActionStyle() -> some View {
        self.buttonStyle(ButtonConfig_Style(color: .intGreen))
    }
    
    func notMainActionStyle() -> some View {
        self.buttonStyle(ButtonConfig_Style(color: .intMoss))
    }
}
