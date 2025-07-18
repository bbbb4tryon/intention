//
//  UserService.swift
//  intention
//
//  Created by Benjamin Tryon on 7/10/25.
//

import Foundation
import SwiftUI

// Stable, anonymous identifier without email or password and services reinstalls
@MainActor
final class UserService: ObservableObject {
    @AppStorage("defaultCategoryID") private var defaultCategoryIDString: String = ""
    @Published private(set) var userID: String = "Empty"
    
    init() {
        Task { @MainActor in
            self.userID = await KeychainHelper.shared.getUserIdentifier()}
        debugPrint("UserService grabs KeychainHelper once")
    }
    
    // Computed fallback ID
    var defaultCategoryID: UUID {
        get {
            if let uuid = UUID(uuidString: defaultCategoryIDString) {
                return uuid
            } else {
                // fallBack: if no valid UUID saved yet
                let newID = UUID()
                defaultCategoryIDString = newID.uuidString
                return newID
            }
        }
        set {
            defaultCategoryIDString = newValue.uuidString
        }
    }
}
