//
//  ScreenStylePalette.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

//  describes feature context
struct ScreenStylePalette {
    let primary: Color
    let background: Color
    let accent: Color
    let text: Color
}
enum ScreenName {
    case homeActiveIntentions, profile, settings, recalibrate
}

extension AppColorTheme {
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch screen {
        case .homeActiveIntentions:
            return .init(primary: .intGreen, background: .intTan, accent: .intSeaGreen, text: .intBrown)
        case .profile:
            return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
        case .settings:
            return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
        case .recalibrate:
            return .init(primary: .purple, background: .gray, accent: .purple.opacity(0.3), text: .yellow.opacity(0.4))
        }
    }
}
