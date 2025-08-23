//
//  AppPreferencesVM.swift
//  intention
//
//  Created by Benjamin Tryon on 8/23/25.
//


import SwiftUI

/// Option A for the delivery mechanism: inject a HapticsService from RootView (no singletons), @MainActor, warmed generators, safe everywhere
@MainActor
final class AppPreferencesVM: ObservableObject {
    @AppStorage("hapticsOnly") var hapticsOnly: Bool = true  /// default ON
    /// optional: add more later (soundsEnabled, reduceAnimations, etc.)
}
