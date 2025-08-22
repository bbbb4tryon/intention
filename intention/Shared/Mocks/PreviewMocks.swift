//
//  PreviewMocks.swift
//  intention
//
//  Created by Benjamin Tryon on 8/6/25.
//

import SwiftUI

enum PreviewMocks {
    // One persistence for everything in previews
    @MainActor static let persistence = PersistenceActor()

    // HistoryVM: single instance + fixed IDs + basic bootstrap
    @MainActor static let history: HistoryVM = {
        let h = HistoryVM(persistence: persistence)
        // Safe static UUIDs for previews
        h.generalCategoryID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        h.archiveCategoryID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        // Create categories if needed
        h.ensureGeneralCategory()
        h.ensureArchiveCategory()
        return h
    }()

    @MainActor static let stats: StatsVM = {
        StatsVM(persistence: persistence)
    }()

    @MainActor static let membershipVM: MembershipVM = {
        MembershipVM()
    }()

    @MainActor static let theme: ThemeManager = {
        ThemeManager()
    }()

    // FocusSessionVM shares the SAME HistoryVM instance
    @MainActor static let focusSession: FocusSessionVM = {
        let vm = FocusSessionVM(previewMode: true, config: .current)
        vm.historyVM = history
        return vm
    }()
}
