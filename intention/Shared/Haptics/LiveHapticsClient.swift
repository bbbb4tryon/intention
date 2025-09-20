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
//    init(prefs: AppPreferencesVM, engine: HapticsService) {
//        light.prepare(); impact.prepare(); heavy.prepare(); notify.prepare()
//    }
    
    /// Pre-warms the generators; safe to call often
    func warm() { prepareGenerators() }
    private func prepareGenerators() {
        light.prepare(); impact.prepare(); heavy.prepare(); notify.prepare()
    }
    
    func added() {      impact.impactOccurred(intensity: 0.8) }
    func warn() {       notify.notificationOccurred(.warning) }
    func notifyDone() {
        notify.notificationOccurred(.success)
        heavy.impactOccurred()
        Task { try? await Task.sleep(nanoseconds: 500_000_000); heavy.impactOccurred()
        try? await Task.sleep(nanoseconds: 250_000_000); heavy.impactOccurred() }
    }
    
//        light.impactOccurred()
//        Task {
//            try? await Task.sleep(nanoseconds: 300_000_000); light.impactOccurred()
//        }
//    }

//     func notifyDone() {
//        /// long, long, short
//         heavy.impactOccurred()
//         Task {
//             try? await Task.sleep(nanoseconds: 500_000_000); heavy.impactOccurred()
//             try? await Task.sleep(nanoseconds: 250_000_000); heavy.impactOccurred()
//         }
//    }
    
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

/// for background tasks, just hop to main when calling: await MainActor.run { haptics.notifyDone() }
/// if the compiler complains/nags:
/// // Live client (wrap engine safely on main)
/// struct LiveHapticsClient: HapticsClient {
///    let prefs: AppPreferencesVM
///    let engine: HapticsService
///    private var enabled: Bool { prefs.hapticsOnly }
///
///    func added() async       { guard enabled else { return }
///        await MainActor.run { engine.tapLight() } }
///
///    func warn() async{ guard enabled else { return }
///        await MainActor.run { engine.doubleLight() } }
///
///    func notifyDone() async  { guard enabled else { return }
///        await MainActor.run { engine.longLongShort() } }
/// }
