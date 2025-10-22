//
//  LegalKeys.swift
//  intention
//
//  Created by Benjamin Tryon on 10/22/25.
//

import SwiftUI

// MARK: - Persisted acceptance state
struct LegalKeys {
    static let acceptedVersion = "legal.acceptedVersion"
    static let acceptedAtEpoch = "legal.acceptedAtEpoch"
}

enum LegalConsent {
    static func needsConsent(currentVersion: Int = LegalConfig.currentVersion) -> Bool {
        UserDefaults.standard.integer(forKey: LegalKeys.acceptedVersion) < currentVersion
    }
    static func recordAcceptance(currentVersion: Int = LegalConfig.currentVersion) {
        UserDefaults.standard.set(currentVersion, forKey: LegalKeys.acceptedVersion)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: LegalKeys.acceptedAtEpoch)
    }
    /// DEBUG: clear all acceptance so the sheet will show again
    static func clearForDebug() {
        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedVersion)
        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedAtEpoch)
    }
}
