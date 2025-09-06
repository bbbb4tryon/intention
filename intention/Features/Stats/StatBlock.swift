//
//  StatBlock.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

struct StatBlock: View {
    @EnvironmentObject var theme: ThemeManager
    let icon: String
    let value: String
    let caption: String
    let screen: ScreenName

    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title2).foregroundStyle(p.accent)
            T(value, .title3).bold().foregroundStyle(p.text)
            T(caption, .caption).foregroundStyle(p.textSecondary)
        }
    }
}
