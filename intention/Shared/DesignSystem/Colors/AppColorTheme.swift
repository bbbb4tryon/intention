//
//  AppColorTheme.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUI

enum AppColorTheme: String, CaseIterable {
    case `default`, sea, fire
    
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .sea: return "Sea"
        case .fire: return "Fire"
        }
    }
    
    var primary: Color {
        switch self {
        case .default: return .intGreen
        case .sea: return .teal
        case .fire: return .orange
        }
    }
    
    var background: Color {
        switch self {
        case .default: return .intTan
        case .sea: return .mint.opacity(0.15)
        case .fire: return .pink.opacity(0.1)
        }
    }
    
//    var ?: Color {
//        switch self {
//        case .default: return .intBrown
//        case .sea: return .??.opacity(0.15)
//        case .fire: return .??.opacity(0.1)
//    }
    
    var accent: Color {
        switch self {
        case .default: return .intMoss
        case .sea: return .cyan
        case .fire: return .red
        }
    }
}

/* NOTE: default color:
 int_brown    #A29877    Serious, grounded — titles, text, nav
 int_green    #226E64    Primary action, intentionality, focus, actions/buttons
 int_mint    #8FD8BC    Calm, welcoming — perfect for profile
 int_moss    #B7CFAF    Soft support — secondary elements
 int_sea_green    #50D7B7    Dynamic/energetic — timers, progress, Animations
 int_tan    #E9DCBC    Neutral background (light mode)
 int_tan (Dark)    #7F7457    Neutral background (dark mode)
 
 FocusSession    intTan    intBrown    intGreen    intSeaGreen
 Profile    intMint    intBrown    intMoss    intSeaGreen badges
 Settings    intTan    intBrown    intGreen    muted intMoss
 Recalibrate    intGreen    intTan    intTan (light on dark)    intMint, intMoss timers
*/
