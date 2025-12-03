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
