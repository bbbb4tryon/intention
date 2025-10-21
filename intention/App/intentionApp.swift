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
    // @StateObject var theme = ThemeManager() //FIXME: - don't need this
    
    init(){
        // Match launch color immediately
        UIWindow.appearance().backgroundColor = UIColor(named: "background")
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .background(Color("LaunchscreenTan").ignoresSafeArea())
        }
    }
}
