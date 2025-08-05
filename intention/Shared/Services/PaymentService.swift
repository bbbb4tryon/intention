//
//  PaymentService.swift
//  intention
//
//  Created by Benjamin Tryon on 8/3/25.
//

import Foundation
import StoreKit

// Handles purchaseds via Storekit 2 logic
final class PaymentService: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isMember: Bool = false
    
    private let membershipProductID = "com.intention.membership"
    
    init() {
        Task { await loadProducts() }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: [membershipProductID])
        } catch {
            debugPrint("[PaymentService] Load failed: ", error)
        }
    }
    
    func purchaseMembership() async {
        guard let product = products.first else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    isMember = true
                    UserDefaults.standard.set(true, forKey: "isMember")
                }
            default:
                break
            }
        } catch {
            debugPrint("[PaymentService] Purchase failed: ", error)
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            debugPrint("[PaymentService] Restore failed: ", error)
        }
    }
    
    func loadMembershipState() {
        isMember = UserDefaults.standard.bool(forKey: "isMember")
    }
}

//#Preview {
//    PaymentService()
//}
