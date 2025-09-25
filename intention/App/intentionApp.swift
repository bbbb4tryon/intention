//
//  intentionApp.swift
//  intention
//
//  Created by Benjamin Tryon on 6/5/25.
//

import SwiftUI

@main
struct intentionApp: App {
    @State private var isBusy = false
    // Theme is the source of truth - and remains here, not in RootView itself
//    @StateObject var theme = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
//                .environmentObject(theme)
                .progressOverlay($isBusy, text: "Loading...")
        }
    }
}
