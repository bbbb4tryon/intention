//
//  MembershipVM.swift
//  intention
//
//  Created by Benjamin Tryon on 8/4/25.
//

import SwiftUI
import StoreKit

enum MembershipError: Error, Equatable, LocalizedError {
    case purchaseFailed, restoreFailed, invalidCode, networkError, appEnvironmentFail

    var errorDescription: String? {
        switch self {
        case .purchaseFailed:     return "Purchase could not be completed."
        case .restoreFailed:      return "No purchases to restore."
        case .invalidCode:        return "That code isn’t valid."
        case .networkError:       return "Network error. Please try again."
        case .appEnvironmentFail: return "App environment error."
        }
    }
}


@MainActor
final class MembershipVM: ObservableObject {
    @Published var isMember: Bool = false
    @Published var shouldPrompt: Bool = false
    @Published var showCodeEntry: Bool = false
    @Published var lastError: Error?                /// Used to trigger the UI visual error overlay
    
    private let paymentService = PaymentService()
    private let codeService = MembershipCodeService()
    
    init() {
        // Ensures MembershipVM initializes PaymentService and calls loadMembershipState() on init
        paymentService.loadMembershipState()
        isMember = paymentService.isMember
    }
    
    func triggerPromptifNeeded(afterSessions sessionCount: Int, threshold: Int = 2){
        if !isMember && sessionCount >= threshold {
            shouldPrompt = true
        }
    }
    
    func purchaseMembershipOrPrompt() async throws {
        await paymentService.purchaseMembership()
        isMember = paymentService.isMember
        shouldPrompt = !isMember
        guard isMember else {
            let err = MembershipError.purchaseFailed
            setError(err)
            throw err
        }
    }
    
    func restoreMembershipOrPrompt() async throws {
        await paymentService.restorePurchases()
        isMember = paymentService.isMember
        guard isMember else {
            let err = MembershipError.restoreFailed
            setError(err)
            throw err
        }
    }
    
    @MainActor
    func verifyCode(_ code: String) async throws {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let result = await codeService.verify(code: code, deviceID: deviceID)
        
        switch result {
        case .success:
            isMember = true
            shouldPrompt = false
            showCodeEntry = false
            
        case .invalid:
            let err = MembershipError.invalidCode
            setError(err)
            throw err
            
        case .networkError:
            let err = MembershipError.networkError
            setError(err)
            throw err
        }
    }
    
    func setError(_ error: Error?) {
        lastError = error
    }
    
    var showSheetBinding: Binding<Bool> {
        Binding(
            get: { self.shouldPrompt },
            set: { newVal in self.shouldPrompt = newVal  }
            // or self.shouldPrompt = $0
        )
    }
}
