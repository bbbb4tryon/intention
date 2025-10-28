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
    
//    @ViewBuilder
//    func metalTexturedGradientEffect(...) -> some View {
//        self.???
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
//    
//    @ViewBuilder
//    func metalGradientifAvailable(...) -> some View {
//        if #available(iOS 18.0, *){
//            self.metalTexturedGradientEffect(isActive: active)
//        } else if #available(iOS 17.0, *){
//            // fallback for ios 17
//            self.????
//        } else {
//            // fallback for ios 16.0
//            self
//        }
//    }
}
