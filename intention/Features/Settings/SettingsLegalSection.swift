//
//  SettingsLegalSection.swift
//  intention
//
//  Created by Benjamin Tryon on 9/8/25.
//

import SwiftUI

struct SettingsLegalSection: View {
    @EnvironmentObject private var theme: ThemeManager
    private let screen: ScreenName = .settings
        private var p: ScreenStylePalette { theme.palette(for: screen) }
        private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }

    var onShowTerms: () -> Void
    var onShowPrivacy: () -> Void
    var onShowMedical: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legal").font(.headline)
            HStack(spacing: 10) {
                Button { onShowTerms() } label: { T("Terms of Use", .tile) }.underline().buttonStyle(.plain)
                Text("•")
                Button { onShowPrivacy() } label: { T("Privacy Policy", .tile) }.underline().buttonStyle(.plain)
                Text("•")
                Button { onShowMedical() }label: { T("Wellness Disclaimer", .tile) }.underline().buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    SettingsLegalSection(onShowTerms: {}, onShowPrivacy: {}, onShowMedical: {})
        .padding()
}
#endif
