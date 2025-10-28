//
//  PreviewsDebug.swift
//  intention
//
//  Created by Benjamin Tryon on 10/26/25.
//
#if DEBUG
import SwiftUI

// Recalibration - Running
#Preview("Recalibration * Running"){
    PreviewWrapper {
        RecalibrationV(vm: RecalibrationVM.mockForDebug()).previewTheme()
    }
}
// Organizer overlay — mock binding
#Preview("Organizer Overlay") {
    MainActor.assumeIsolated {
        @State var cats: [CategoriesModel] = [
            // …seed a couple of categories with a few tiles…
        ]
        return OrganizerOverlayChrome(onClose: {}) {
            OrganizerOverlayScreen(
                categories: $cats,
                onMoveTile: { _,_,_ in },
                onReorder: { _,_ in },
                onDone: {}
            )
        }
        .environmentObject(PreviewMocks.theme)
    }
}

// Membership sheet — non-member
#Preview("Membership — Not Active") {
    MainActor.assumeIsolated {
        let memberVM = MembershipVM(payment: PaymentService(productIDs: ["com.argonnesoftware.intention"]))
        memberVM._debugSetIsMember(false)
        return MembershipSheetV()
            .environmentObject(PreviewMocks.theme)
            .environmentObject(memberVM)
            .environmentObject(PreviewMocks.prefs)
            .environmentObject(PreviewMocks.history)
            .environmentObject(PreviewMocks.stats)
    }
}
#endif
