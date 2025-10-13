//
//  PreviewMocks.swift
//  intention
//
//  Created by Benjamin Tryon on 8/6/25.
//

#if DEBUG
import SwiftUI

enum PreviewMocks {
    // One persistence for everything in previews
    @MainActor static let persistence = PersistenceActor()

    @MainActor static let history: HistoryVM = {
        let h = HistoryVM(persistence: persistence)
        h.generalCategoryID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        h.archiveCategoryID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        h.ensureGeneralCategory()
        h.ensureArchiveCategory()
        return h
    }()

    @MainActor static let stats: StatsVM = {
        StatsVM(persistence: persistence)
    }()

// inject PaymentService(productIDs:) and use the VM’s debug setter
    @MainActor static let membershipVM: MembershipVM = {
        let svc = PaymentService(productIDs: ["com.argonnesoftware.intention"])
        let vm  = MembershipVM(payment: svc)
        #if DEBUG
        vm._debugSetIsMember(false)   // Preview non-member state; flip to true if needed
        #endif
        return vm
    }()

    @MainActor static let prefs: AppPreferencesVM = {
        AppPreferencesVM()
    }()
    
    @MainActor static let theme: ThemeManager = {
        ThemeManager()
    }()

    @MainActor static let focusSession: FocusSessionVM = {
        let vm = FocusSessionVM(previewMode: true,
                                haptics: NoopHapticsClient(),    // ← ignore haptics in previews
                                config: .current)                 // your TimerConfig already returns .shortDebug in previews
        vm.historyVM = history
        return vm
    }()
    
    @MainActor static let recal: RecalibrationVM = {
            RecalibrationVM(haptics: NoopHapticsClient())             // ← ignore in previews

        }()
}
#endif

// @StateObject private var focusVM: FocusSessionVM
// @StateObject private var recalibrationVM: RecalibrationVM
// @StateObject private var prefs: AppPreferencesVM
// @StateObject private var haptics: HapticsService
