//
//  DebugPreviewFlags.swift
//  intention
//
//  Created by Benjamin Tryon on 11/1/25.

import Foundation

@inline(__always)
var IS_PREVIEW: Bool {
    #if DEBUG
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] != nil
    #else
    return false
    #endif
}

/// Wrap any async/side-effect call you never want to run in Canvas.
@inline(__always)
func previewGuard(_ work: () -> Void) {
    if !IS_PREVIEW { work() }
}

extension View {
    /// Disable animations + transitions in Canvas (avoids AG graph thrash).
    func canvasCheap() -> some View {
        self
            .transaction { t in
                t.disablesAnimations = true
                t.animation = nil
            }
    }
}
