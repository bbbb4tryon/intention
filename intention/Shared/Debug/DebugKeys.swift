//
//  DebugKeys.swift
//  intention
//
//  Created by Benjamin Tryon on 9/12/25.
//

import SwiftUI

struct DebugKeys {
    static let forceLegalNextLaunch = "debug.forceLegalNextLaunch"
}

/// Call once at app startup (e.g., in App/RootView.onAppear)
func bootstrapLegalGate() {
    // Test plan env var still works if you keep using it
    if ProcessInfo.processInfo.environment["RESET_LEGAL_ON_LAUNCH"] == "1" {
        LegalConsent.clearForDebug()
    }
    if UserDefaults.standard.bool(forKey: DebugKeys.forceLegalNextLaunch) {
        LegalConsent.clearForDebug()
        UserDefaults.standard.set(false, forKey: DebugKeys.forceLegalNextLaunch)
    }
}
