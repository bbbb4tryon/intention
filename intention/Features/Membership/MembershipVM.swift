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
}


@MainActor
final class MembershipVM: ObservableObject {
    @Published var isMember: Bool = false
    @Published var shouldPrompt: Bool = false
    @Published var showCodeEntry: Bool = false
    @Published var lastError: Error?
    
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
        
        if !isMember {
            throw MembershipError.purchaseFailed
        }
    }
    
    func restoreMembershipOrPrompt() async throws {
        await paymentService.restorePurchases()
        isMember = paymentService.isMember
        
        if !isMember {
            throw MembershipError.restoreFailed
        }
    }
    
    func verifyCode(_ code: String) async {
        Task {
            do {
                let result = await codeService.verify(code: code, deviceID: UIDevice.current.identifierForVendor?.uuidString ?? "unknown")
                
                switch result {
                case .success:
                    self.isMember = true
                    self.shouldPrompt = false
                    self.showCodeEntry = false
                    
                case .invalid:
                    throw MembershipError.invalidCode
                    
                case .networkError:
                    throw MembershipError.networkError
                }
                
            } catch {
                debugPrint("[MembershipVM.verifyCode] error: ", error)
                await MainActor.run { self.lastError = error }
            }
        }
    }
}
extension MembershipVM {
    var showSheetBinding: Binding<Bool> {
        Binding(get: { self.shouldPrompt }, set: { newVal in self.shouldPrompt = newVal }
        )
    }
}

