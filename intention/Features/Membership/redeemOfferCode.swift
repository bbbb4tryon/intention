//
//  redeemOfferCode.swift
//  intention
//
//  Created by Benjamin Tryon on 9/25/25.
//

import Foundation
import StoreKit

@MainActor
func redeemOfferCode() async {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        try? await AppStore.presentOfferCodeRedeemSheet(in: scene)   // iOS 16+
    }
}
