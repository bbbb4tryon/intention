//
//  ButtonSee.swift
//  intention
//
//  Created by Benjamin Tryon on 6/17/25.
//

import SwiftUI

struct ButtonSee: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ButtonSee()
}

enum ScreenStyleKind {
    typealias ScreenName = (
//        homeActiveIntentions: Color, profile: Color, settings: Color, recalibrate: Color
        notRecalibrate: Color, recalibrate: Color
    )
    
    typealias ComponentColor = (
        primary: Color, background: Color, accent: Color, text: Color
    )
    private typealias StateColor = (
        )
    
//    let blueOpacity = Color.blue.opacity(0.2)
//    case indigo, blue.opacity(0.2), cyan.opacity(0.6), white
}
