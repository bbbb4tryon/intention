//
//  SubtleModifier.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUI

// Visually consistent animations
struct SubtleModifier: ViewModifier {
    let delay: Double
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .transition(
                .opacity
                    .combined(with: .opacity)
            )
            .animation(
                .smooth(extraBounce: 0.1),
                value: UUID()   // Runs even w same value
            )
        
    }
}

extension View {
    func subtleMod(
        from delay: Double = 0.0,
        offset: CGFloat = 1
        
    ) -> some View {
        self.modifier(SubtleModifier(delay: delay, offset: offset))
    }
}

#Preview {
    let focus = FocusSessionVM()
    let recal = RecalibrationVM()
    FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
}
