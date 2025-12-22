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
    @Published var showDebug = false
    
    // Optional payload for a global error overlay
    @Published var showError = false
    @Published var errorTitle: String = "Debug Error"
    @Published var errorMessage: String = "This is a sample error"
//    
//    // MARK: Unlock state
//    @Published var askForPin = false
//    @Published private(set) var isUnlocked = false
    
    // MARK: Config
    private let requiredPin = DebugSecrets.requiredPIN
    private let failHandoffDelay: TimeInterval = 0.15
    
    init() { }
    
    // MARK: Debug access gate (left swipe)
    // value.startLocation.x < 24 && value.translation.width > 60 and flip the sign test; for swipe at right edge
    func presentDebugGated(timeout: TimeInterval){
        guard BuildInfo.isDebugOrTestFlight else { return }
        requirePINThen(expected: requiredPin, within: timeout) { [weak self] in
            Task { @MainActor in self?.showDebug = true }
        } onFail: { [weak self] in
         // brief delay for alert animation
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(self?.failHandoffDelay ?? 0.15 * 1_000_000_000))
                self?.showDebug = false
            }
        }
    }
    
    // MARK: Dev debug points
    func presentRecalibration() { showRecalibration = true }
    func presentMembership()    { showMembership = true }
    
    func presentError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }
}
