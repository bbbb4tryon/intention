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
    
//    func metalTexturedGradient(strength: Double = 0.06, animate: Bool = false) -> some View {
//        self.visualEffect { content, proxy in
//            content.layerEffect(
//                ShaderLibrary.noiseShader(
//                    .boundingRect,
//                    .float(proxy.size.width),
//                    .float(proxy.size.height),
//                    .float(animate ? proxy.time : 0.0),     // animate or freeze
//                    .float(strength)
//                ),
//                maxSampleOffset: .zero
//            )
//        }
//    }
}

extension View {
    @ViewBuilder
    func symbolBounceIfAvailable(active: Bool = true) -> some View {
        if #available(iOS 18.0, *) {
            self.bounceSymbolEffect(isActive: active)               /// uses .bounce only in an iOS18 context
        } else if #available(iOS 17.0, *) {
            /// fallback for iOS 17
            self.symbolEffect(.pulse, isActive: active)
        } else {
            self
        }
    }
    
    //FIXME: -  affect does this have now?
    @ViewBuilder
    func safeAreaTopPadding() -> some View {
        if #available(iOS 17.0, *) {
            self.safeAreaPadding(.top)      /// adjusts with device & bars
        } else {
            self.padding(.top)              /// simple fallback
        }
    }
//    /// Cross-version "grain" for gradients: iOS 18 = Metal shader, older = tiled PNG overlay
//    @ViewBuilder
//    func texturedGradient(strength: Double = 0.06, animate: Bool = false) -> some View {
//        if #available(iOS 18.0, *) {
//            self.metalTexturedGradient(strength: strength, animate: animate)
//        } else {
//            // Fallback: drop a tiny seamless noise tile in Assets ("noise-tile-256")
//            self.overlay(
//                Image("noise-tile-256")
//                    .resizable()
//                    .scaledToFill()
//                    .opacity(strength)
//                    .allowsHitTesting(false)
//            )
//            .clipped()
//        }
//    }
}
