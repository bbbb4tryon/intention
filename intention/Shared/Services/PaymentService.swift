//
//  PaymentService.swift
//  intention
//
//  Created by Benjamin Tryon on 8/3/25.
//

import Foundation
import StoreKit

// Service = "how". Actor is concurrency-safe and long-term correct.
// Owns StoreKit logic of products, entitlement refresh, refunds/cancellations
/// Apple processes payment; app never sees card info; Only reads entitlements (transactions) and set isMember; keeping app "anonymous" (device-scoped)
//final class PaymentService: ObservableObject {

public struct PaymentState: Sendable, Equatable {
    public var isMember: Bool
    public var products: [Product]
}

public actor PaymentService {
    private let productIDs: [String]
    private var productsCache: [Product] = []
    private var isMemberCache: Bool = false
//    @Published private(set) var isMember: Bool = false
    
    // Async plumbing
    private var continuations: [AsyncStream<PaymentState>.Continuation] = []
    
    public init(productIDs: [String]) {
        self.productIDs = productIDs
    }
    
    public func configure() async {
        await listenForTransactions()
        await refreshEntitlementStatus()
        // Start listening for transaction updates
        Task.detached { [weak self] in
            guard let self else { return }
            for await _ in Transaction.updates {
                await self.refreshEntitlementStatus()
            }
        }
    }
    
    public func updates() -> AsyncStream<PaymentState> {
        AsyncStream { cont in
            continuations.append(cont)
            // Immediately emit current snapshot
            cont.yield(.init(isMember: isMemberCache, products: productsCache))
            cont.onTermination = { [weak self] _ in
                guard let self else { return }
                self.continuations.removeAll { $0 === cont }
            }
        }
    }
    
    //   MARK: Queries
    public func products() -> [Product] { productsCache }
    public func isMember() -> Bool { isMemberCache }
    
    
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
    
    // MARK: Entitlement hydration
    public func refreshEntitlementStatus() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let t) = entitlement else { continue }
            if t.productID == membershipProductID, t.revocationDate == nil {
                active = true
            }
        }
    isMemberCache = active
        notify()
    }
    
    private let membershipProductID = "com.argonnesoftware.intention"
    private var updatesTask: Task<Void, Never>?
//    
//    init() {
//        /// Start updates (refunds/cancellation)  listener and hydrate state
//        updatesTask = listenForTransactions()
//        Task { await loadProducts(); await refreshEntitlementStatus() }
//    }
  
    deinit { updatesTask?.cancel() }
    
    // MARK: Purchasing
    /// Verifies and finishes Purchase via call sites; returns true only when a verified entitlement exists
    @discardableResult
    public func purchaseMembership() async throws -> Bool {
        guard let product = productsCache.first else {
            // Ensure products are loaded at least once
            //            await refreshProducts()
            guard let prod = productsCache.first else { throw StoreKitError.unknown }
            return try await purchase(prod: prod)
        }
        return try await purchase(prod: product)
    }
    
    private func purchase(prod: Product) async throws -> Bool {
            let result = try await prod.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Finish and refresh entitlements
                    await transaction.finish()                                        /// No `try` - it's async, not throws
                    await refreshEntitlementStatus()
                    return true
                case .unverified:
                    return false
                }
//                if case .verified = verification {
//                    isMember = true
//                    UserDefaults.standard.set(true, forKey: "isMember")
//                }
            case .userCancelled, .pending:
                // FIXME: overlay
                debugPrint("[PaymentService] user cancelled")
                return false
                @unknown default:
                // FIXME: overlay
                debugPrint("[PaymentService] Purchase failed")
                return false
        }
    }
    
    public func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            await refreshEntitlementStatus()
        } catch {
            debugPrint("[PaymentService] Restore failed: ", error)
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
    
    private func notify() {
        let snapshot = PaymentState(isMember: isMemberCache, products: productsCache)
        continuations.forEach { $0.yield(snapshot) }
    }
}
// #if DEBUG
// #Preview {
//    PaymentService()
// }
// #endIf
