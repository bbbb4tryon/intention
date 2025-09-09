//
//  KeychainHelper.swift
//  intention
//
//  Created by Benjamin Tryon on 7/10/25.
//

import Foundation
import Security

actor KeychainHelper {
    //    any issues with KeychainHelper as an actor,
    //    change to final class KeychainHelper: @unchecked Sendable { static let standard = KeychainHelper
    //      // _ same methods, but add 'async' AND call await KeychainHelper.shared.getUserIdentifier()
    
    static let shared = KeychainHelper()
    private init() {}
    
    /// Grabs system-provided bundle ID string - `private let` restrict `service` to that file
    private let service = Bundle.main.bundleIdentifier!
    private let account = "anonymousUserID"
    
    /// Returns the existing UUID, or generates+stores a new one
    func getUserIdentifier() -> String {
        if let existing = readUUID() {
            return existing
        } else {
            let newID = UUID().uuidString
            saveUUID(newID)
            #if DEBUG
            debugPrint("KeychainHelper: newID - \(newID)")
            #endif
            return newID
        }
    }
    
    /// Keep saveUUID() and readUUID() synchronous internally - no "async"
    private func saveUUID(_ uuid: String) {
            let data = Data(uuid.utf8)
            let query: [String: Any] = [
                kSecClass as String       : kSecClassGenericPassword,
                kSecAttrService as String : service,
                kSecAttrAccount as String : account,
                kSecValueData as String   : data
            ]
            // Remove any old and add new
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
    
    private func readUUID() -> String? {
            let query: [String: Any] = [
                kSecClass as String       : kSecClassGenericPassword,
                kSecAttrService as String : service,
                kSecAttrAccount as String : account,
                kSecReturnData as String  : true,
                kSecMatchLimit as String  : kSecMatchLimitOne
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            guard status == errSecSuccess,
                  let data = result as? Data,
                  let str = String(data: data, encoding: .utf8)
            else { return nil }
            return str
        }
}
