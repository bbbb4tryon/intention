// DebugRouter.swift
// intention
//
// A tiny @MainActor router that your Dev buttons call.
// RootView observes it and presents the right sheet/overlay.

import SwiftUI

@MainActor
final class DebugRouter: ObservableObject {
    // Presentation toggles
    @Published var showRecalibration = false
    @Published var showMembership = false
    @Published var showTab: Bool = false
    
    // Optional payload for a global error overlay
    @Published var showError = false
    @Published var errorTitle: String = "Debug Error"
    @Published var errorMessage: String = "This is a sample error"
    
    // MARK: Unlock state
    @Published var askForPin = false
    @Published private(set) var isUnlocked = false
    
    // MARK: Config
    private let pinKey = "debug_unlock_pin"     // Userdefault key for cached unlock expiry
    private let unlockTTL: TimeInterval = 12 * 60 * 60 // 12h cache
    private let requiredPin = "1521"            // change as needed; in DEBUG you can keep this
    
    init() {
        // restores cached unlock if still valid
        if let until = UserDefaults.standard.object(forKey: pinKey) as? Date, until > Date() {
            isUnlocked = true
            showTab = true
        }
    }
    
    // Call on triple-tap -> shows PIN sheet if not yet unlocked
    func requestUnlockFromTripleTap() {
        guard BuildInfo.isDebugOrTestFlight else { return }
        if isUnlocked { showTab = true }
        else { askForPin = true }
    }
    
    // MARK: Call Z-Gesture
    func unlockFromZGesture() {
        guard BuildInfo.isDebugOrTestFlight else { return }
        isUnlocked = true
        cacheUnlock()
        showTab = true
    }
    
    func submit(pin: String) {
        guard BuildInfo.isDebugOrTestFlight else { return }
        if pin == requiredPin {
            isUnlocked = true
            cacheUnlock()
            showTab = true
            askForPin = false
        } else {
            // keep sheet open
        }
    }
    
    private func cacheUnlock() {
        UserDefaults.standard.set(Date().addingTimeInterval(unlockTTL), forKey: pinKey)
    }
    
    // MARK: Entry points the Dev buttons will call
    func toggleTab() { showTab.toggle() }
    func presentRecalibration() { showRecalibration = true }
    func presentMembership()    { showMembership = true }
    
    func presentError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }
}
