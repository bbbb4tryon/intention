//
//  ZGestureOpener.swift
//  intention
//
//  Created by Benjamin Tryon on 12/3/25.
//

import SwiftUI

// MARK: - Z gesture opener (minimal heuristic, plain SwiftUI)
struct ZGestureOpener: ViewModifier {
    let onTrigger: () -> Void
    @State private var points: [CGPoint] = []
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onChanged { val in
                                    points.append(val.location)
                                }
                                .onEnded { _ in
                                    if isZLike(in: geo.size, pts: points) { onTrigger() }
                                    points.removeAll(keepingCapacity: true)
                                }
                        )
                }
            )
    }
    
    // Very simple "Z" detector:
    // - start near top, end near bottom
    // - first third reaches far right
    // - middle dips left
    // - last third returns right
    private func isZLike(in size: CGSize, pts: [CGPoint]) -> Bool {
        guard pts.count >= 12 else { return false }
        let h = size.height, w = size.width
        let start = pts.first!, end = pts.last!
        guard start.y < h * 0.30, end.y > h * 0.70 else { return false }
        
        let third = max(1, pts.count / 3)
        let firstSeg  = pts[0..<third]
        let middleSeg = pts[third..<min(third*2, pts.count)]
        let lastSeg   = pts[min(third*2, pts.count-1)..<pts.count]
        
        let firstMaxX  = firstSeg.map(\.x).max() ?? 0
        let middleMinX = middleSeg.map(\.x).min() ?? w
        let lastMaxX   = lastSeg.map(\.x).max() ?? 0
        
        // Require a noticeable right-left-right pattern
        let rightEnough = (firstMaxX > w * 0.65) && (lastMaxX > w * 0.65)
        let leftDip     = (middleMinX < w * 0.35)
        return rightEnough && leftDip
    }
}
