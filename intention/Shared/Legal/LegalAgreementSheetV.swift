//
//  LegalAgreementSheetV.swift
//  intention
//
//  Created by Benjamin Tryon on 9/4/25.
//

import SwiftUI

struct LegalAgreementSheetV: View {
    @EnvironmentObject private var theme: ThemeManager
    private let screen: ScreenName = .settings
        private var p: ScreenStylePalette { theme.palette(for: screen) }
        private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }

    let onAccept: () -> Void
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void
    var onShowMedical: (() -> Void)?   // optional extra link
    
    // --- Local Color Definitions for Legal ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        NavigationStack {
        VStack(spacing: 14){
            T("Please review the policies below. By tapping **Agree & Continue**, you accept them.", .body)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                
                // Links row
            HStack(alignment: .center, spacing: 10) {
                Button { onShowTerms() } label: { T("Terms", .label).underline() }
                    .buttonStyle(.plain).underline()
                T("•", .secondary).foregroundStyle(.tertiary)
                
                Button{ onShowPrivacy() } label: { T("Privacy Policy", .label).underline() }
                    .buttonStyle(.plain).underline()
                }
//                .font(.subheadline)
                
                if let onShowMedical {
                    Button { onShowMedical() } label: { T("Wellness Disclaimer", .label).underline() }
                        .buttonStyle(.plain)
                }
               
//                Spacer(minLength: 0)
            }
            .frame(maxWidth: 520)
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
            // Full-screen style
            .presentationDetents([.large])
            .safeAreaInset(edge: .bottom){
                // Sticky, always-visible CTA area
                VStack(spacing: 8){
                    Button("Agree & Continue", action: onAccept)
                        .buttonStyle(.borderedProminent)
                        .tint(p.accent)
                        .controlSize(.large)

                    T("You can review these anytime in **Settings › Legal**.", .caption)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(.ultraThinMaterial)
            }
        }
    }
}

#if DEBUG
#Preview {
    PreviewWrapper {
        LegalAgreementSheetV(
            onAccept: {},
            onShowTerms: {},
            onShowPrivacy: {}
        )
    }
}
#endif
