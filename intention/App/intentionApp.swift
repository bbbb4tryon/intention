//
//  intentionApp.swift
//  intention
//
//  Created by Benjamin Tryon on 6/5/25.
//

import SwiftUI

@main
struct intentionApp: App {
    /// Theme is the source of truth for colors at launch.
    
    init(){
        // Match launch color immediately
        UIWindow.appearance().backgroundColor = UIColor(named: "AppBackground")
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .background(ThemeManager.appBackgroundColor.ignoresSafeArea())
//                .background(Color("AppBackground").ignoresSafeArea())
        }
    }
}

