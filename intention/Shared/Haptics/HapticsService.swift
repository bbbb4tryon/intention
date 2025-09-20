//
//  HapticService.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//
//
//import Foundation
//import UIKit
//
//// Option A for the delivery mechanism: inject a HapticsService from RootView (no singletons), @MainActor, warmed generators, safe everywhere
//@MainActor
//final class HapticsService: ObservableObject {
//    private let light = UIImpactFeedbackGenerator(style: .light)
//    private let medium = UIImpactFeedbackGenerator(style: .medium)
//    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
//    
//    init() {
//        light.prepare(); medium.prepare(); heavy.prepare()
//    }
//    
//    func added() {
//        medium.impactOccurred()
//    }
//    
//    func warn() {
//        /// short, short
//        light.impactOccurred()
//        Task {
//            try? await Task.sleep(nanoseconds: 300_000_000); light.impactOccurred()
//        }
//    }
//
//     func notifyDone() {
//        /// long, long, short
//         heavy.impactOccurred()
//         Task {
//             try? await Task.sleep(nanoseconds: 500_000_000); heavy.impactOccurred()
//             try? await Task.sleep(nanoseconds: 250_000_000); heavy.impactOccurred()
//         }
//    }
//    
//}
