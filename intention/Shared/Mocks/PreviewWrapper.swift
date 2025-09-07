//
//  PreviewWrapper.swift
//  intention
//
//  Created by Benjamin Tryon on 8/6/25.
//

#if DEBUG
import SwiftUI

@MainActor
struct PreviewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .environmentObject(PreviewMocks.theme)
            .environmentObject(PreviewMocks.prefs)
            .environmentObject(PreviewMocks.membershipVM)
            .environmentObject(PreviewMocks.history)        /// some subviews use HistoryVM via EnvironmentObject
            .environmentObject(PreviewMocks.stats)
    }
}
#endif
