//
//  ScreenStylePalette.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

// MARK: - Describes feature context
struct ScreenStylePalette {
    let primary: Color
    let background: Color
    let accent: Color
    let text: Color
}
enum ScreenName {
    case homeActiveIntentions, history, settings, recalibrate
}

// MARK: - ScreenStylePalette per Theme
// .colors(for screen:) implementation per AppColorTheme

extension AppColorTheme {
    func colors(for screen: ScreenName) -> ScreenStylePalette {
        switch self {
        case .default:
            switch screen {
            case .homeActiveIntentions:
                return .init(primary: .intGreen, background: .intTan, accent: .intSeaGreen, text: .intBrown)
            case .history:
                return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
            case .settings:
                return .init(primary: .intMint, background: .intTan, accent: .intSeaGreen, text: .intBrown)
            case .recalibrate:
                return .init(primary: .intSeaGreen, background: .intBrown.opacity(0.3), accent: .intGreen, text: .yellow.opacity(0.4))
            }

        case .sea:
            switch screen {
            case .homeActiveIntentions:
                return .init(primary: .teal, background: .mint.opacity(0.15), accent: .cyan, text: .blue)
            case .history:
                return .init(primary: .mint, background: .mint.opacity(0.15), accent: .cyan.opacity(0.4), text: .teal)
            case .settings:
                return .init(primary: .teal, background: .mint.opacity(0.2), accent: .cyan.opacity(0.5), text: .teal)
            case .recalibrate:
                return .init(primary: .indigo, background: .teal.opacity(0.2), accent: .mint.opacity(0.6), text: .cyan)
            }

        case .fire:
            switch screen {
            case .homeActiveIntentions:
                return .init(primary: .orange, background: .pink.opacity(0.1), accent: .red.opacity(0.6), text: .brown)
            case .history:
                return .init(primary: .orange, background: .pink.opacity(0.15), accent: .red.opacity(0.5), text: .brown)
            case .settings:
                return .init(primary: .orange, background: .pink.opacity(0.05), accent: .red.opacity(0.4), text: .brown)
            case .recalibrate:
                return .init(primary: .black.opacity(0.85), background: .red, accent: .orange.opacity(0.3), text: .white)
            }
        }
    }
}

