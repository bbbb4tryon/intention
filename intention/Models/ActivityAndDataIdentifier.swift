//
//  ActivityAndDataIdentifier.swift
//  intention
//
//  Created by Benjamin Tryon on 7/8/25.
//

import Foundation

//  Generate UUID on first launch
//      - user identified anonymously but trackable
//  Store (locally) UUID for persistence
//  Use to track history and sessions, no User input needed
func getUserIdentifier() -> String {
    if let storedUUID = UserDefaults.standard.string(forKey: "userUUID") {
        return storedUUID
    } else {
        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: "userUUID")
        return newUUID
    }
}
