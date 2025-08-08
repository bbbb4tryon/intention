//
//  PreviewMocks.swift
//  intention
//
//  Created by Benjamin Tryon on 8/6/25.
//

import SwiftUI

enum PreviewMocks {
    @MainActor static var persistence: Persistence {    PersistenceActor()  }
    
    @MainActor static var stats: StatsVM {
        StatsVM(persistence: persistence)
    }
    
    @MainActor static var history: HistoryVM {
        HistoryVM(persistence: persistence)
    }
    
    @MainActor static var userService: UserService {
        UserService()
    }
    @MainActor static var theme: ThemeManager {
        ThemeManager()
    }
    @MainActor static var membershipVM: MembershipVM {
        MembershipVM()
    }
}
