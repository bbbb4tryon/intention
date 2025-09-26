//
//  MembershipCodeService.swift
//  intention
//
//  Created by Benjamin Tryon on 8/4/25.
//

import Foundation

// Apple Pay: users expect no codes. Just the StoreKit sheet → done.
// Stripe/web: a simple redeem code screen is the most anonymous and familiar approach without accounts.
//Redeem Code Screen:
//
//They pay, see a short code (6–10 chars).
//
//In the app, they go to “Enter Code”, type/paste it.
//
//App unlocks.
//
//--Familiar from gift cards and beta programs.
//
//-- No email or account but still feels anonymous but valid.

actor MembershipCodeService {
    
    enum VerificationResult {
        case success
        case invalid
        case networkError
    }
    
    // Replace with backend URL
    private let verifyEndpoint = URL(string: "https://argonnesoftware.com/api/verify")!
    
    func verify(code: String, deviceID: String) async -> VerificationResult {
        // FIXME: Placeholder - similate network verification
        try? await Task.sleep(nanoseconds: 500_000_000)       // 0.5s delay

        // FIXME: In production: POST code to backend and check response
        if code.uppercased() == "INTENTION-BETA" {
            UserDefaults.standard.set(true, forKey: "isMember")
            return .success
        } else {
            return .invalid
        }
    }
}
