//
//  SettingsLegalSection.swift
//  intention
//
//  Created by Benjamin Tryon on 9/8/25.
//

import SwiftUI

struct SettingsLegalSection: View {
    var onShowTerms: () -> Void
    var onShowPrivacy: () -> Void
    var onShowMedical: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legal").font(.headline)
            HStack(spacing: 10) {
                Button("Terms of Use") { onShowTerms() }.buttonStyle(.plain).underline()
                Text("•")
                Button("Privacy Policy") { onShowPrivacy() }.buttonStyle(.plain).underline()
                Text("•")
                Button("Wellness Disclaimer") { onShowMedical() }.buttonStyle(.plain).underline()
            }
            .font(.footnote)
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
