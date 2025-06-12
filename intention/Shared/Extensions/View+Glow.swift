//
//  View+Glow.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

extension View {
    func glow(color: Color = .intTan, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: Color.intTan, radius: radius / 3)
    }
}

#Preview {
    FocusSessionActiveV()
}
