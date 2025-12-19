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
/// `isMember` flips only from verified entitlements in PaymentService.refreshEntitlementStatus(), and the VM just mirrors that via updates()
@MainActor
final class MembershipVM: ObservableObject {
    // UI state mirrored from PaymentService
    @Published private(set) var isMember: Bool = false
    @Published var shouldPrompt: Bool = false
    @Published var showCodeEntry: Bool = false
    @Published var primaryProduct: Product?         /// Shows "¢/day • $X.XX"
    @Published var lastError: Error?                /// Used to trigger the UI visual error overlay
    
    let payment: PaymentService             //FIXME: only use the injected instance, and not p let paymentService = PaymentService()?
    private let codeService = MembershipCodeService()
    
    init(payment: PaymentService) {
        self.payment = payment
        // Observe payment service state
        // "Mirror service state" (✅ this is how VM learns membership)
        Task {
            for await state in await payment.updates(){
                self.isMember = state.isMember
                self.primaryProduct = state.products.first
            }
        }
        // Initial configuration
        Task { await payment.configure() }
    }
        
//        paymentService.$isMember
//            .receive(on: RunLoop.main)
//            .assign(to: &$isMember)
//        
//        paymentService.$products
//            .map { $0.first }   // FIXME: not $0, what is 0 made of?
//            .receive(on: RunLoop.main)
//            .assign(to: &$primaryProduct)
//    }

    func buy() async {
        do {
            let paid = try await payment.purchaseMembership()
            if !paid { await payment.refreshEntitlementStatus() }
        } catch {
            lastError = error
        }
    }
    
    /// Trigger helper to reopen form anywhere (starts in RootView, can be in a banner, Settings, locked feature)
    @MainActor func presentPaywall() { shouldPrompt = true }

    func restore() async {
        do {
            try await payment.restorePurchases()
            if !isMember { lastError = MembershipError.restoreFailed }
        } catch {
            lastError = error
        }
    }

    // Public UI API (never sets isMember directly)
    func purchaseMembershipOrPrompt() async throws {
        let before = isMember
        do {
            let paid = try await payment.purchaseMembership()
            await payment.refreshEntitlementStatus()
            shouldPrompt = false
//            shouldPrompt = !(paid || isMember)
            if !(paid || isMember) { throw MembershipError.purchaseFailed }
        } catch is CancellationError {
            // User backed out. Don’t keep a spinner/prompt up.
            shouldPrompt = false
            lastError = nil
        }
        catch {
            shouldPrompt = !isMember
            lastError = error
            throw error
        }
    }
    
    func restoreMembershipOrPrompt() async throws {
        do {
            try await payment.restorePurchases()
            shouldPrompt = false
            if !isMember { throw MembershipError.restoreFailed }
            } catch {
                let err = MembershipError.restoreFailed; setError(err); throw err
        }
    }
    
    @MainActor
    func verifyCode(_ code: String) async throws {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let result = await codeService.verify(code: code, deviceID: deviceID)
        switch result {
        case .success:
            // Treat as an unlocked entitlement
            isMember = true
            shouldPrompt = false
            showCodeEntry = false
        case .invalid:
            let err = MembershipError.invalidCode; setError(err); throw err
        case .networkError:
            let err = MembershipError.networkError; setError(err); throw err
        }
    }
    
    func triggerPromptIfNeeded(afterSessions sessionCount: Int, threshold: Int = 2) {
        if !isMember && sessionCount >= threshold { shouldPrompt = true }
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
            // ^ aka, self.shouldPrompt = $0
        )
    }
    
    #if DEBUG
    // Preview/testing hook to flip membership without touching StoreKit
    // because this method is inside the type, it can write to the private(set) property
    func _debugSetIsMember(_ value: Bool) { self.isMember = value }
    #endif
}
