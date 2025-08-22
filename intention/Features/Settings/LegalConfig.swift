//
//  LegalConfig.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//


import SwiftUI

enum LegalConfig {
    static let currentVersion = 1
    static let termsFile = "terms_v1"      // terms_v1.md in bundle
    static let privacyFile = "privacy_v1"  // privacy_v1.md in bundle

    // When your website goes live, just use these in Settings if you prefer web:
    static let termsURL = URL(string: "https://argonnesoftware.com/terms")!
    static let privacyURL = URL(string: "https://argonnesoftware.com/privacy")!
}

// Persist acceptance state
struct LegalKeys {
    static let acceptedVersion = "legal.acceptedVersion"
    static let acceptedAtEpoch = "legal.acceptedAtEpoch"
}
