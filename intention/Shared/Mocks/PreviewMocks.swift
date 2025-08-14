//
//  PreviewMocks.swift
//  intention
//
//  Created by Benjamin Tryon on 8/6/25.
//

import SwiftUI

enum PreviewMocks {
    
    @MainActor static var userService: UserService {
        let service = UserService()
        /// Safe static UUIDs for previews — avoids crashing on invalid strings
                service.defaultCategoryID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
                service.archiveCategoryID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        return service
    }
    @MainActor static var persistence: Persistence {
        PersistenceActor()
    }
    
    @MainActor static var history: HistoryVM {
        HistoryVM(persistence: persistence, userService: userService)
    }
    
    @MainActor static var stats: StatsVM {
        StatsVM(persistence: persistence)
    }

    @MainActor static var membershipVM: MembershipVM {
        MembershipVM()
    }
    
    @MainActor static var focusSession: FocusSessionVM {
        /// Always short in previews
        FocusSessionVM(previewMode: true, config: .current)
    }
    
    @MainActor static var theme: ThemeManager {
        ThemeManager()
    }
}
