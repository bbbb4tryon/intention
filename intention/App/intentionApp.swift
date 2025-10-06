//
//  intentionApp.swift
//  intention
//
//  Created by Benjamin Tryon on 6/5/25.
//

import SwiftUI

@main
struct intentionApp: App {
    // Theme is the source of truth - and remains here, not in RootView itself
//    @StateObject var theme = ThemeManager()
    
    init(){
        // UIWindow match launch color immediately
        UIWindow.appearance().backgroundColor = UIColor(named: "background")
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .background(Color("LaunchscreenTan").ignoresSafeArea())
//                .environmentObject(theme)
        }
    }
}
