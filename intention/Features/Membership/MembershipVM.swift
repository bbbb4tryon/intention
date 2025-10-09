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

/// pure async/await for purchase/restore paths, one paywall, stable entitlement refresh
@MainActor
final class MembershipVM: ObservableObject {
    // UI state mirrored from PaymentService
    @Published private(set) var isMember: Bool = false
    @Published var shouldPrompt: Bool = false
    @Published var showCodeEntry: Bool = false
    @Published var primaryProduct: Product?         /// Shows "¢/day • $X.XX"
    @Published var lastError: Error?                /// Used to trigger the UI visual error overlay
    
    private let payment: PaymentService
    private let codeService = MembershipCodeService()
    
    init(payment: PaymentService) {
        // Ensures MembershipVM initializes PaymentService and calls loadMembershipState() on init
        /// Mirror enitlement + first product for UI
        //        paymentService.loadMembershipState()
        //        isMember = paymentService.isMember
        
        self.paymentService = payment
        Task { await payment.configure() }
        paymentService.$isMember
            .receive(on: RunLoop.main)
            .assign(to: &$isMember)
        
        paymentService.$products
            .map { $0.first }   // FIXME: not $0, what is 0 made of?
            .receive(on: RunLoop.main)
            .assign(to: &$primaryProduct)
    }
    func buy() async {
        do {
            let paid = try await paymentService.purchaseMembership()
            if !paid { await paymentService.refreshEntitlementStatus() }
        } catch { lastError = error }
    }

    func restore() async { await paymentService.restorePurchases(); await refreshEntitlementStatus(); if !isMember { lastError = MembershipError.restoreFailed }
    }

        private func refreshEntitlement() async {
            isMember = await paymentService.active
    }
    
    func triggerPromptIfNeeded(afterSessions sessionCount: Int, threshold: Int = 2) {
        if !isMember && sessionCount >= threshold { shouldPrompt = true }
    }
    
    /// Trigger helper to reopen form anywhere (starts in RootView, can be in a banner, Settings, locked feature)
    @MainActor func presentPaywall() { shouldPrompt = true }
    
    /// Core remains async throws. UI calls inside Task { do/try/catch }
    func purchaseMembershipOrPrompt() async throws {
        try await paymentService.purchaseMembership()
        isMember = paymentService.isMember
        shouldPrompt = !isMember
        guard isMember else {
            let err = MembershipError.purchaseFailed
            setError(err)
            throw err
        }
    }
    
    func restoreMembershipOrPrompt() async throws {
        try await paymentService.restorePurchases()
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
    
    func setError(_ error: Error?) { lastError = error }
    
    func perDayBlurb(for product: Product) -> String {
        guard let sub = product.subscription else { return "" }
        // Very rough: 30-day month, 365-day year. It’s just a blurb.
        let days: Decimal
        switch sub.subscriptionPeriod.unit {
        case .month: days = 30
        case .year:  days = 365
        case .week:  days = 7
        case .day:   days = 1
        @unknown default: days = 30
        }
        // Product.price is Decimal in StoreKit 2.
        let daily = (product.price / days) as NSDecimalNumber
        let cents = (daily.multiplying(by: 100)).doubleValue.rounded()
        return "about \(Int(cents))¢/day"
    }
    
    var showSheetBinding: Binding<Bool> {
        Binding(
            get: { self.shouldPrompt },
            set: { newVal in self.shouldPrompt = newVal  }
            // or self.shouldPrompt = $0
        )
    }
}
