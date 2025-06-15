//
//  ScreenTheme.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUI

enum ScreenTheme {
    case focus, profile, settings, recalibrate
//    
//    var primaryColor: Color {
//        switch self {
//        case .recalibrate: return .intTan
//        default: return .intBrown
//        }
//        
//        var backgroundColor: Color {
//            switch self {
//            case .recalibrate: return .intTan
//            default: return .intBrown
//            }
//            var accentColor: Color {
//                switch self {
//                case .recalibrate: return .intTan
//                default: return .intBrown
//                }
//                var textColor: Color {
//                    switch self {
//                    case .recalibrate: return .intTan
//                    default: return .intBrown
//                    }
    var backgroundColor: Color {
        switch self {
        case .focus: return .intTan
        case .profile: return .intMint
        case .settings: return .intTan
        case .recalibrate: return .intGreen
        }
    }
    
    var titleColor: Color {
        switch self {
        case .recalibrate: return .intTan
        default: return .intBrown
        }
        
//        return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
    }
}
/*
FocusSession    intTan    intBrown    intGreen    intSeaGreen
Profile    intMint    intBrown    intMoss    intSeaGreen badges
Settings    intTan    intBrown    intGreen    muted intMoss
Recalibrate    intGreen    intTan    intTan (light on dark)    intMint, intMoss timers

*/
