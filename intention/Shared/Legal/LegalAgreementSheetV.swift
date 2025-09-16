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

    var body: some View {
        NavigationStack {
            Page(top: 20, alignment: .center) {

                    Text("""
                    Please review the policies below. 
                    By tapping **Agree & Continue**, 
                    you accept them.
                    """
                    )
//                    .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
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
                
                // spacer before CTA (larger gap)
                Spacer().frame(height: 12)
                Button("Agree & Continue") { onAccept() }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)                    // makes it filled
                .buttonBorderShape(.roundedRectangle(radius: 14))   // FIXME: remove and only need .controlSize(.large
                .tint(.blue)                                        // fill color
                .controlSize(.large)
                
                // Footnote hint
                Text("You can review these anytime in **Settings › Legal**.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: 520)                    // keeps measure pleasant on large screens
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium, .large])
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
