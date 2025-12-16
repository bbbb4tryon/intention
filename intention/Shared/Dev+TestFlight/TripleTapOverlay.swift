//
//  TripleTapOverlay.swift
//  intention
//
//  Created by Benjamin Tryon on 12/4/25.
//

import SwiftUI

/// Sits over the tab bar area, listens for triple-tap WITHOUT blocking the tab bar.
struct TripleTapOverlay: UIViewRepresentable {
    let height: CGFloat
    let onTripleTap: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTripleTap: onTripleTap) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.backgroundColor = .clear
        
        let gr = UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleTap(_:))
        )
        gr.numberOfTapsRequired = 3
        gr.cancelsTouchesInView = false
        v.addGestureRecognizer(gr)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator {
        let onTripleTap: (CGPoint) -> Void
        init(onTripleTap: @escaping (CGPoint) -> Void) { self.onTripleTap = onTripleTap }
        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            let pt = gr.location(in: gr.view)
            onTripleTap(pt)
        }
    }
}
