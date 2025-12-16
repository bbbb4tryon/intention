//
//  DebugHitBox.swift
//  intention
//
//  Created by Benjamin Tryon on 12/16/25.
//

// Attached to suspected places - overlays, anywhere with safeAreaInset)...
// Watch for print when when "add" is tapped, that layer is the culprit
// the Fix: flip .allowsHitTesting(false) or move its zIndex below the content.

import SwiftUI

struct DebugHitBox: View {
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .overlay(
                Text("HIT LAYER")
                    .font(.caption2).padding(4)
                    .background(.red.opacity(0.8)).foregroundStyle(.white)
                    .cornerRadius(4)
            )
            .onTapGesture { print("🔴 Top layer ate a tap") }
    }
}

#Preview {
    DebugHitBox()
}
