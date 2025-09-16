//
//  LiveHapticsClient.swift
//  intention
//
//  Created by Benjamin Tryon on 8/23/25.
//

import Foundation

/// avoid pushing both a preference object and a service into every VM: wrap them behind a protocol that gates haptics based on the preference
/// VMs then depend on one thing: HapticsClient
@MainActor
protocol HapticsClient {
    func added()
    func countdownTick()
    func notifySwitch()
    func notifyDone()
}

/// No-op (for tests or to disable globally)
struct NoopHapticsClient: HapticsClient {
    func added() {}
    func countdownTick() {}
    func notifySwitch() {}
    func notifyDone() {}
}

/// Live client that checks prefs.hapticsOnly and calls the engine
// @MainActor
struct LiveHapticsClient: HapticsClient {
    let prefs: AppPreferencesVM
    let engine: HapticsService
    private var enabled: Bool { prefs.hapticsOnly }

    func added() { guard enabled else { return }; engine.added() }
    func countdownTick() { guard enabled else { return }; engine.countdownTick() }
    func notifySwitch() { guard enabled else { return }; engine.notifySwitch() }
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
///    func notifySwitch() async{ guard enabled else { return }
///        await MainActor.run { engine.doubleLight() } }
///
///    func notifyDone() async  { guard enabled else { return }
///        await MainActor.run { engine.longLongShort() } }
/// }
