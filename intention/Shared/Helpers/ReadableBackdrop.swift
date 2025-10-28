//
//  ReadableBackdrop.swift
//  intention
//
//  Created by Benjamin Tryon on 10/27/25.
//


import SwiftUI

public struct ReadableBackdrop: ViewModifier {
    let background: Color
    let target: Double
    let textColor: Color

    public func body(content: Content) -> some View {
        // If our *desired* textColor already meets target vs background, skip the chip.
        if textColor.contrastRatio(against: background) >= target {
            content
        } else {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

public extension View {
    func readableBackdrop(ifAgainst bg: Color, textColor: Color, target: Double = 6.1) -> some View {
        modifier(ReadableBackdrop(background: bg, target: target, textColor: textColor))
    }
}
