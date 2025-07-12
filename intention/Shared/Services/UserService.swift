//
//  UserService.swift
//  intention
//
//  Created by Benjamin Tryon on 7/10/25.
//

import Foundation

// Stable, anonymous identifier without email or password and services reinstalls
final class UserService: ObservableObject {
    @Published private(set) var userID: String = "Empty"
    
    init() {
        Task { @MainActor in
            self.userID = await KeychainHelper.shared.getUserIdentifier()}
        debugPrint("UserService grabs KeychainHelper once")
    }
}
