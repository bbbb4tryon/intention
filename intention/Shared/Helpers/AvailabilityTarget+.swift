//
//  AvailabilityTarget+.swift
//  intention
//
//  Created by Benjamin Tryon on 8/8/25.
//
import SwiftUI

// iOS 18-only helper so .bounce never appears in a broader-availability symbol
@available(iOS 18.0, *)
private extension View {
    @ViewBuilder
    func bounceSymbolEffect(isActive: Bool) -> some View {
        self.symbolEffect(.bounce, isActive: isActive)
    }
}

extension View {
    @ViewBuilder
    func symbolBounceIfAvailable(active: Bool = true) -> some View {
        if #available(iOS 18.0, *) {
            self.bounceSymbolEffect(isActive: active)   // uses .bounce only in an iOS18 context
        } else if #available(iOS 17.0, *) {
            // Fallback for iOS 17 (choose any 17-compatible effect)
            self.symbolEffect(.pulse, isActive: active)
        } else {
            self
        }
    }
}
