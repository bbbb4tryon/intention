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
//    @Published var showOrganizer = false
    @Published var showMembership = false
    
    // Optional payload for a global error overlay
    @Published var errorTitle: String = ""
    @Published var errorMessage: String = ""
    @Published var showError = false
    
    // MARK: Entry points the Dev buttons will call
    func presentRecalibration() { showRecalibration = true }
//    func presentOrganizer()     { showOrganizer = true }
    func presentMembership()    { showMembership = true }
    
    func presentError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }
}
