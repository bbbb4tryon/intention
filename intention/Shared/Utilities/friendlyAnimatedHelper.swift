//
//  friendlyAnimatedHelper.swift
//  intention
//
//  Created by Benjamin Tryon on 8/23/25.
//

import SwiftUI

extension View {
    /// Mark as a rotor-friendly heading
    func friendlyHelper() -> some View { self.accessibilityAddTraits(.isHeader) }

    /// Gate animations for motion sensitivity
    func friendlyAnimatedHelper(_ value: AnyHashable, animation: Animation = .easeInOut) -> some View {
        modifier(AnimatedIfAllowed(value: value, animation: animation))
    }
}

private struct AnimatedIfAllowed<V: Hashable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: V
    let animation: Animation
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}
