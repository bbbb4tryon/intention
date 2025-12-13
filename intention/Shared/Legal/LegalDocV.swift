//
//  LegalDocV.swift
//  intention
//
//  Created by Benjamin Tryon on 10/22/25.
//

import SwiftUI

// MARK: Reusable Markdown screen
struct LegalDocV: View {
//    @EnvironmentObject var theme: ThemeManager
//
    
    let title: String
    let markdown: String
    // Restricted to value, no OO or EO, lets the sheet control it
    let palette: ScreenStylePalette
    
    /// Theme hooks
//    private let screen: ScreenName = .focus
//    private var p: ScreenStylePalette { theme.palette(for: screen) }
//    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        ScrollView {
            SimpleMarkdownView(markdown: markdown)
                .frame(maxWidth: 700)
                .foregroundStyle(palette.text)
        }
//        .background(p.background.ignoresSafeArea())
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollIndicators(.hidden)
    }
}
