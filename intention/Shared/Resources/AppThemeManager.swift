//
//  AppThemeManager.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

final class AppThemeManager {
    @AppStorage("selectedColorTheme") private var colorRaw: String = AppColorTheme.default.rawValue
    @AppStorage("selectedFontTheme") private var fontRaw: String = AppFontTheme.serif.rawValue
    
    
    static let shared = AppThemeManager()
    
    var color: AppColorTheme {
        AppColorTheme(rawValue: colorRaw) ?? .default
    }
    
    var font: AppFontTheme {
        AppFontTheme(rawValue: fontRaw) ?? .serif
    }
    
    func updateColor(to theme: AppColorTheme) {
        colorRaw = theme.rawValue
    }
    
    func updateFont(to theme: AppFontTheme) {
        fontRaw = theme.rawValue
    }
}
