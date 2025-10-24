//
//  LiveHapticsClient.swift
//  intention
//
//  Created by Benjamin Tryon on 8/23/25.
//

import Foundation
import UIKit

@MainActor
final class HapticsService: ObservableObject {
    private let light   = UIImpactFeedbackGenerator(style: .light)
    private let impact  = UIImpactFeedbackGenerator(style: .medium)
    private let heavy   = UIImpactFeedbackGenerator(style: .heavy)
    private let notify  = UINotificationFeedbackGenerator()
    
    init() { prepareGenerators() }
    
    /// Pre-warms the generators; safe to call often
    func warm() { prepareGenerators() }
    private func prepareGenerators() {
        light.prepare(); impact.prepare(); heavy.prepare(); notify.prepare()
    }
    
    func added() { impact.impactOccurred(intensity: 0.8) }
    func warn() { notify.notificationOccurred(.warning) }
    func notifyDone() {
        heavy.impactOccurred()                      // 1st heavy
        
        Task {
            let longerPause: UInt64 = 200_000_000   // 200 million nanoseconds - 200 milisecdons
            let shortPause: UInt64 = 90_000_000     // 90 million nanoseconds - 90 milisecdons
            // wait; second heavy
            try? await Task.sleep(nanoseconds: longerPause); heavy.impactOccurred()
            // wait; third heavy
            try? await Task.sleep(nanoseconds: shortPause); heavy.impactOccurred()
            // wait; last heavy
            try? await Task.sleep(nanoseconds: shortPause); heavy.impactOccurred()
        }
        notify.notificationOccurred(.success)
    }
}
/// Gates haptics; VMs only talk to this protocol
@MainActor
protocol HapticsClient {
    func added()
    func warn()
    func notifyDone()
}

/// No-op (for tests or to disable globally)
struct NoopHapticsClient: HapticsClient {
    func added() {}
    func warn() {}
    func notifyDone() {}
}

/// Live client that checks prefs.hapticsOnly and calls the engine
 @MainActor
struct LiveHapticsClient: HapticsClient {
    let prefs: AppPreferencesVM
    let engine: HapticsService
    private var enabled: Bool { prefs.hapticsOnly }

    func added()    { guard enabled else { return }; engine.added() }
    func warn()     { guard enabled else { return }; engine.warn() }
    func notifyDone() { guard enabled else { return }; engine.notifyDone() }
}
