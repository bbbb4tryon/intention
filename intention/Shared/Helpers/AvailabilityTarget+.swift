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
    
    /// Metal-based grain with system-driven animation time (no custom timers).
        @ViewBuilder
        func metalTexturedGradient(strength: Double = 0.06) -> some View {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                // Preview fallback: no Metal toolchain needed
                self.overlay(
                    Image("noise-tile-256")
                        .resizable()
                        .scaledToFill()
                        .opacity(strength)
                        .allowsHitTesting(false)
                )
                .clipped()
            } else {
                // Real device/simulator build: animated shader via TimelineView
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    self.visualEffect { content, proxy in
                        content.layerEffect(
                            ShaderLibrary.noiseShader(
                                .boundingRect,
                                .float(proxy.size.width),
                                .float(proxy.size.height),
                                .float(t),
                                .float(strength)
                            ),
                            maxSampleOffset: .zero
                        )
                    }
                }
            }
            #else
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                self.visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.noiseShader(
                            .boundingRect,
                            .float(proxy.size.width),
                            .float(proxy.size.height),
                            .float(t),
                            .float(strength)
                        ),
                        maxSampleOffset: .zero
                    )
                }
            }
            #endif
        }
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
    /// Cross-version "grain" for gradients:
    /// - iOS 18: animated via TimelineView(.animation)
    /// - iOS 17 and earlier: static tiled PNG overlay
    @ViewBuilder
    func texturedGradient(strength: Double = 0.06) -> some View {
        if #available(iOS 18.0, *) {
            self.metalTexturedGradient(strength: strength)
        } else {
            self.overlay(
                Image("noise-tile-256")
                    .resizable()
                    .scaledToFill()
                    .opacity(strength)
                    .allowsHitTesting(false)
            )
            .clipped()
        }
    }
}
