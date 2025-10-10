//
//  PaymentService.swift
//  intention
//
//  Created by Benjamin Tryon on 8/3/25.
//

import StoreKit

// Service = "how". Actor is concurrency-safe and long-term correct.
// Owns StoreKit logic of products, entitlement refresh, refunds/cancellations
/// Apple processes payment; app never sees card info; Only reads entitlements (transactions) and set isMember; keeping app "anonymous" (device-scoped)
public struct PaymentState: Sendable, Equatable {
    public var isMember: Bool
    public var products: [Product]
}

public actor PaymentService {
    private let productIDs: [String]
    private var productsCache: [Product] = []
    private var isMemberCache: Bool = false
    
    // Async plumbing
    private var continuations: [UUID: AsyncStream<PaymentState>.Continuation] = [:]
    private var updatesTask: Task<Void, Never>?
    
    public init(productIDs: [String]) {
        self.productIDs = productIDs
    }
    
    // RootView calls this once, at launch
    public func configure() async {
        await refreshProducts()
        await refreshEntitlementStatus()
        // Start listening for transaction updates
        updatesTask?.cancel()
        updatesTask = listenForTransactions()
    }
    
    deinit { updatesTask?.cancel() }
    
    //
    //    public func updates() -> AsyncStream<PaymentState> {
    //        AsyncStream { cont in
    //            continuations.append(cont)
    //            // Immediately emit current snapshot
    //            cont.yield(.init(isMember: isMemberCache, products: productsCache))
    //            cont.onTermination = { [weak self] _ in
    //                guard let self else { return }
    //                self.continuations.removeAll { $0 === cont }
    //            }
    //        }
    //    }
    
    public func updates() -> AsyncStream<PaymentState> {
        AsyncStream { cont in
            let id = UUID()
            continuations[id] = cont
            // Immediately emit current snapshot
            cont.yield(.init(isMember: isMemberCache, products: productsCache))
            cont.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }
    
    // MARK: Queries
    public func products() -> [Product] { productsCache }
    public func isMember() -> Bool { isMemberCache }
    
    // MARK: Entitlement hydration
    public func refreshEntitlementStatus() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let t) = entitlement else { continue }
            if t.productID == productIDs.first, t.revocationDate == nil {
                active = true
            }
        }
        isMemberCache = active
        notify()
    }
    
    // MARK: Products
    public func refreshProducts() async {
        do {
            let prods = try await Product.products(for: productIDs)
            productsCache = prods.sorted(by: { $0.price < $1.price })
            notify()
        } catch {
            // leave cache as-is
        }
    }
    
    // MARK: Purchase/Restore
    @discardableResult
    public func purchaseMembership() async throws -> Bool {
        let product: Product
        if let first = productsCache.first {
            product = first
        } else {
            await refreshProducts()
            guard let loaded = productsCache.first else { throw StoreKitError.unknown }
            product = loaded
        }
        
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await refreshEntitlementStatus()
                return true
            case .unverified:
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
    
    public func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlementStatus()
    }
    
    
    // MARK: internally, close-scoped
    private func listenForTransactions() -> Task<Void, Never> {
        // Capture while on the actor
        let targetID = self.productIDs.first
        
        return Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                do {
                    // Pure helper, no actor state involved
                    let transaction = try checkVerified(result)
                    
                    if transaction.productID == targetID {
                        await self.refreshEntitlementStatus()
                    }
                    await transaction.finish()
                } catch {
                    // ignore unverified
                }
            }
        }
    }
    
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let err): throw err
        }
    }
    
    private func notify() {
        let snapshot = PaymentState(isMember: isMemberCache, products: productsCache)
        for cont in continuations.values { cont.yield(snapshot) }
    }
    
    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    
    
    private let membershipProductID = "com.argonnesoftware.intention"
    //
    //    init() {
    //        /// Start updates (refunds/cancellation)  listener and hydrate state
    //        updatesTask = listenForTransactions()
    //        Task { await loadProducts(); await refreshEntitlementStatus() }
    //    }
    

}
