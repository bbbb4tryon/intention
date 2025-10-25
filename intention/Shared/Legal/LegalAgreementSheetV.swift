//
//  LegalAgreementSheetV.swift
//  intention
//
//  Created by Benjamin Tryon on 9/4/25.
//

import SwiftUI

struct LegalAgreementSheetV: View {
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
                Text("Please review the policies below. By tapping **Agree & Continue**, you accept them.")
                .multilineTextAlignment(.leading)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                
                // Links row
                HStack(alignment: .center) {
                    Button("Terms") { onShowTerms() }
                        .buttonStyle(.plain).underline()
                    Text("•").foregroundStyle(.tertiary)
                    Button("Privacy Policy") { onShowPrivacy() }
                        .buttonStyle(.plain).underline()
                }
                .font(.subheadline)
                
                if let onShowMedical {
                    Button("Wellness Disclaimer") { onShowMedical() }
                        .buttonStyle(.plain)
                        .underline()
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                        .tint(.blue)
                        .controlSize(.large)

                    Text("You can review these anytime in **Settings › Legal**.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
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
    LegalAgreementSheetV(
        onAccept: {},
        onShowTerms: {},
        onShowPrivacy: {}
    )
}
#endif
