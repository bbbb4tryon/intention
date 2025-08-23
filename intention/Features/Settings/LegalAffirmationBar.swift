//
//  LegalAffirmationBar.swift
//  intention
//
//  Created by Benjamin Tryon on 8/22/25.
//


import SwiftUI

struct LegalAffirmationBar: View {
    let onAgree: () -> Void
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button("Terms") { onShowTerms() }.buttonStyle(.plain).underline()
                    Text("and").font(.footnote).foregroundStyle(.secondary)
                    Button("Privacy") { onShowPrivacy() }.buttonStyle(.plain).underline()
                }
            }
            Spacer()
            Button("Agree") { onAgree() }
                .primaryActionStyle(screen: .settings)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 2, y: 1)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
