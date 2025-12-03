//
//  AppPreferencesVM.swift
//  intention
//
//  Created by Benjamin Tryon on 8/23/25.
//

import SwiftUI

/// The delivery mechanism: inject a HapticsService from RootView (no singletons), @MainActor, warmed generators, safe everywhere
@MainActor
final class AppPreferencesVM: ObservableObject {
    @AppStorage("hapticsOnly") var hapticsOnly: Bool = true  /// default ON
    @AppStorage("showSwatches") var showSwatches: Bool = false
    @AppStorage("soundEnabled") var soundEnabled: Bool = false
    @AppStorage("debugShortTimers") var debugShortTimers: Bool = false
    
    /// optional: add more later ( reduceAnimations, etc.)
}
