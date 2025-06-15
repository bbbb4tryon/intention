//
//  AppFontTheme.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUI

enum AppFontTheme: String, CaseIterable {
    case serif, rounded, mono
    
    var displayName: String {
        switch self {
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .mono: return "Mono"
        }
    }
    
    var titleFont: Font {
        switch self {
        case .serif: return .system(.title, design: .serif).bold()
        case .rounded: return .system(.title, design: .rounded).bold()
        case .mono: return .system(.title, design: .monospaced).bold()
        }
    }
    
    
    var bodyFont: Font {
        switch self {
        case .serif: return .system(.title, design: .serif).bold()
        case .rounded: return .system(.title, design: .rounded).bold()
        case .mono: return .system(.title, design: .monospaced).bold()
        }
    }
}


//extension AppFontTheme {
//    var font: Font {
//        switch self {
//        case .serif: return .system(.body, design: .serif)
//        case .rounded: return .system(.body, design: .rounded)
//        case .mono: return .system(.body, design: .monospaced)
//        }
//    }
//}

extension AppFontTheme {
    func toFont(_ style: Font.TextStyle) -> Font {
        switch self {
                    case .serif: return .system(.body, design: .serif)
                    case .rounded: return .system(.body, design: .rounded)
                    case .mono: return .system(.body, design: .monospaced)
        }
    }
}
