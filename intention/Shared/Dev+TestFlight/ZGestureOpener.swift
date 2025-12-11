////
////  ZGestureOpener.swift
////  intention
////
////  Created by Benjamin Tryon on 12/3/25.
////

import SwiftUI

struct ZGestureOpener: ViewModifier {
    let onTrigger: () -> Void
    @State private var points: [CGPoint] = []
    
    func body(content: Content) -> some View {
        content
        
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { val in points.append(val.location) }
                    .onEnded { _ in
                        if isZLike(points) { onTrigger() }
                        points.removeAll(keepingCapacity: true)
                    }
            )
    }
    /// Very simple "Z" detector using only the traced points:
    /// - start near top, end near bottom (relative to trace bounds)
    /// - first third reaches far right, middle dips left, last third returns right
    private func isZLike(_ pts: [CGPoint]) -> Bool {
        guard pts.count >= 12 else { return false }
        // Bounds of the trace to normalize without needing a view size
        let minX = pts.map(\.x).min() ?? 0
        let maxX = pts.map(\.x).max() ?? 0
        let minY = pts.map(\.y).min() ?? 0
        let maxY = pts.map(\.y).max() ?? 0
        let w = max(maxX - minX, 1) // avoid div-by-zero
        let h = max(maxY - minY, 1)

        guard let start = pts.first, let end = pts.last else { return false }
        // normalize to 0...1 space
        let startYn = (start.y - minY) / h
        let endYn   = (end.y   - minY) / h
        // start near top (<= 0.3), end near bottom (>= 0.7)
        guard startYn <= 0.30, endYn >= 0.70 else { return false }

        // Split into thirds
        let third = max(1, pts.count / 3)
        let firstSeg  = pts[0..<third]
        let middleSeg = pts[third..<min(third*2, pts.count)]
        let lastSeg   = pts[min(third*2, pts.count-1)..<pts.count]

        // Extremes along X (normalized 0...1)
        let firstMaxX  = ((firstSeg.map(\.x).max() ?? minX) - minX) / w
        let middleMinX = ((middleSeg.map(\.x).min() ?? maxX) - minX) / w
        let lastMaxX   = ((lastSeg.map(\.x).max() ?? minX) - minX) / w

        // Require a noticeable right-left-right pattern
        let rightEnough = (firstMaxX >= 0.65) && (lastMaxX >= 0.65)
        let leftDip     = (middleMinX <= 0.35)
        return rightEnough && leftDip
    }
    
   }
