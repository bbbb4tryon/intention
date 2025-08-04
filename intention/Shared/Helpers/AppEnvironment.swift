//
//  AppEnvironment.swift
//  intention
//
//  Created by Benjamin Tryon on 8/4/25.
//

import Foundation

struct AppEnvironment {
    static let isAppStoreReviewing: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()
}
