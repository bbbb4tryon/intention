//
//  MembershipSectionV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/22/25.
//
//
/// DON'T NEED THIS - it is an extra purchase entry point
//import SwiftUI
//import StoreKit
//
//private extension Product.SubscriptionPeriod.Unit {
//    var displayText: String {
//        switch self {
//        case .day: "day"
//        case .week: "week"
//        case .month: "month"
//        case .year: "year"
//        @unknown default: "period"
//        }
//    }
//}
//
//struct MembershipSectionV: View {
//    @StateObject private var pay = PaymentService()
//
//    private var priceLine: String {
//        guard let p = pay.products.first else { return "Loading…" }
//        if let sub = p.subscription {
//            return "\(p.displayPrice) / \(sub.subscriptionPeriod.unit.displayText)"
//        }
//        return p.displayPrice
//    }
//
//    var body: some View {
//        Section("Membership") {
//            HStack {
//                Text(pay.isMember ? "Status: Active" : "Status: Not Active")
//                    .foregroundStyle(pay.isMember ? .green : .secondary)
//                Spacer()
//            }
//
//            if let product = pay.products.first {
//                Button("Start Membership — \(priceLine)") {
//                    Task { try await pay.purchaseMembership() }
//                }
//                .primaryActionStyle(screen: .settings
//
//                Button("Restore Purchases") {
//                    Task { try await pay.restorePurchases() }
//                }
//
//                Link("Manage Subscription",
//                     destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
//                    .foregroundStyle(.secondary)
//            } else {
//                ProgressView("Loading products…")
//            }
//        }
//    }
//}
