//
//  MembershipVM.swift
//  intention
//
//  Created by Benjamin Tryon on 8/4/25.
//

import SwiftUI
import StoreKit

@MainActor
final class MembershipVM: ObservableObject {
    @Published var isMember: Bool = false
    @Published var shouldPrompt: Bool = false
    @Published var showCodeEntry: Bool = false
    @Published var lastError: String?
    
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
    
    func purchaseMembershipOrPrompt() async {
        await paymentService.purchaseMembership()
        isMember = paymentService.isMember
        shouldPrompt = !isMember
    }
    
    func restoreMembershipOrPrompt() async {
        await paymentService.restorePurchases()
        isMember = paymentService.isMember
    }
    
    func verifyCode(_ code: String) async {
        let result = await codeService.verify(code: code, deviceID: UIDevice.current.identifierForVendor?.uuidString ?? "unknown")
        switch result {
        case .success:
            await MainActor.run {
                self.isMember = true
                self.shouldPrompt = false
                self.showCodeEntry = false
            }
        case .invalid:
            await MainActor.run { self.lastError = "Invalid code. Please try again." }
        case .networkError:
            await MainActor.run { self.lastError = "Network error. Try later." }
        }
    }
}
