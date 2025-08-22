//
//  LegalConsent.swift
//  intention
//
//  Created by Benjamin Tryon on 8/22/25.
//

import SwiftUI

enum LegalConsent {
    static func needsConsent(currentVersion: Int = LegalConfig.currentVersion) -> Bool {
        UserDefaults.standard.integer(forKey: LegalKeys.acceptedVersion) < currentVersion
    }
    static func recordAcceptance(currentVersion: Int = LegalConfig.currentVersion) {
        UserDefaults.standard.set(currentVersion, forKey: LegalKeys.acceptedVersion)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: LegalKeys.acceptedAtEpoch)
    }
}
