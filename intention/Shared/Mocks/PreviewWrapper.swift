//
//  PreviewWrapper.swift
//  intention
//
//  Created by Benjamin Tryon on 8/6/25.
//


import SwiftUI

@MainActor
struct PreviewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .environmentObject(PreviewMocks.stats)
            .environmentObject(PreviewMocks.userService)
            .environmentObject(PreviewMocks.theme)
            .environmentObject(PreviewMocks.membershipVM)
    }
}
