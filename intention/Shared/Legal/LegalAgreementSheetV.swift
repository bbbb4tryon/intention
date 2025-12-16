//
//  LegalAgreementSheetV.swift
//  intention
//
//  Created by Benjamin Tryon on 9/4/25.
//

import SwiftUI

struct LegalAgreementSheetV: View {
    @EnvironmentObject private var theme: ThemeManager
    
    let onAccept: () -> Void
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void
    var onShowMedical: (() -> Void)?   // optional extra link
    
    // --- Local Color Definitions for Legal ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    /// Theme hooks
    private let screen: ScreenName = .focus
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                p.background.ignoresSafeArea()
                
                VStack(spacing: 14){
                    T("Made By And For Humans", .body)
                        .padding()
                        .padding(.top, 8)
                    
                    T("Please review the policies below. By tapping *Agree & Continue*, you accept them.", .body)
                    
                    // Links row
                    HStack(alignment: .center, spacing: 10) {
                        Button {
                            Task { @MainActor in onShowTerms() }
                        } label: { T("Policies & Agreements", .label).underline() }
                            .buttonStyle(.plain).underline()
                    }
                    .padding(.top, 8)
                    Spacer(minLength: 0)
                        .frame(maxWidth: 520)
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
                        Button("Agree & Continue") {
                            Task { @MainActor in onAccept() }
                        }
                            .buttonStyle(.borderedProminent)
                            .tint(p.accent)
                            .controlSize(.large)
                        
                        T("You can review these anytime in Settings › Legal.", .caption)
                    }
                    .padding(.top, 24)
//                    Spacer(minLength: 0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(.ultraThinMaterial)
                }
                
            }
        }
    }
}

#if DEBUG
#Preview("Legal Sheet (dumb)") {
    let theme = ThemeManager()

    LegalAgreementSheetV(
        onAccept: {},
        onShowTerms: {},
        onShowPrivacy: {}
    )
    .environmentObject(theme)
    .frame(maxWidth: 430)
}
#endif
