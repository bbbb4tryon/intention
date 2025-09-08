//
//  PaymentService.swift
//  intention
//
//  Created by Benjamin Tryon on 8/3/25.
//

import Foundation
import StoreKit

// Owns StoreKit logic of products, entitlement refresh, refunds/cancellations
/// Apple processes payment; app never sees card info; Only reads entitlements (transactions) and set isMember; keeping app "anonymous" (device-scoped)
final class PaymentService: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isMember: Bool = false
    
    private let membershipProductID = "com.intention.membership"
    private var updateTask: Task<Void, Never>?
    
    init() {
        /// Start updates (refunds/cancellation)  listener and hydrate state
        updateTask = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlementStatus() }
    }
    
    deinit { updateTask?.cancel() }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: [membershipProductID])
        } catch {
            debugPrint("[PaymentService] Load failed: ", error)
        }
    }
    
    /// Verifies and finishes via call sites
    func purchaseMembership() async throws {
        guard let product = products.first else { return }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let t = try checkVerified(verification)
                await t.finish()                                        /// No `try` - it's async, not throws
                await refreshEntitlementStatus()
//                if case .verified = verification {
//                    isMember = true
//                    UserDefaults.standard.set(true, forKey: "isMember")
//                }
            case .userCancelled, .pending:
                //FIXME: overlay
                debugPrint("[PaymentService] user cancelled")
                break
            @unknown default:
                //FIXME: overlay
                debugPrint("[PaymentService] Purchase failed")
                break
        }
    }
    
    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            await refreshEntitlementStatus()
        } catch {
            debugPrint("[PaymentService] Restore failed: ", error)
        }
    }
    
    // MARK: Entitlement hydration
    func refreshEntitlementStatus() async {
        var active = false
        for await status in Transaction.currentEntitlements {
            guard case .verified(let t) = status else { continue }
            if t.productID == membershipProductID, t.revocationDate == nil {
                active = true
            }
        }
        isMember = active                                               /// Explain
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await update in Transaction.updates {
                do {
                    let t = try checkVerified(update)
                    if t.productID == membershipProductID {
                        await refreshEntitlementStatus()
                    }
                    await t.finish()
                } catch {
                    debugPrint("[PaymentService] update error: ", error)
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified(_, let err): throw err
        }
    }
    func loadMembershipState() {
        isMember = UserDefaults.standard.bool(forKey: "isMember")
    }
}
//#if DEBUG
//#Preview {
//    PaymentService()
//}
//#endIf
