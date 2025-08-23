//
//  HapticService.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import Foundation
import UIKit

//Option A for the delivery mechanism: inject a HapticsService from RootView (no singletons), @MainActor, warmed generators, safe everywhere
@MainActor
final class HapticsService: ObservableObject {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    
    init() {
        light.prepare(); medium.prepare(); heavy.prepare()
    }
    
    func added() {
        medium.impactOccurred()
    }
    
    
    func countdownTick() {
        // short
        medium.impactOccurred()
        light.prepare()
    }
    
    func halfway() {
        // short
        medium.impactOccurred()
        Task { try? await Task.sleep(nanoseconds: 200_000_000); light.impactOccurred() }
    }


     func notifyDone() {
        // long, long, short
        for delay in [0.0, 1.0, 2.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }
    
    static func notifySwitch() {
        // short, short
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    static func notifySuccessfullyAdded() {
        // short
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
}
