//
//  intentionApp.swift
//  intention
//
//  Created by Benjamin Tryon on 6/5/25.
//

import SwiftUI

//@main
//struct intentionApp: App {
//    var body: some Scene {
//        WindowGroup {
//            FocusSessionActiveV()
//        }
//    }
//}

@main
struct intentionApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                FocusSessionActiveV()
                .tabItem {
                    Label("", systemImage: "home.fill")
                }
                SettingsV()
                    .tabItem {
                        Label("", systemImage: "gear.fill")
                    }
                HistoryV()
                    .tabItem {
                        Label("", systemImage: "script.fill")
                    }
            }
        }
    }
}
