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

    @State private var agree = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Before You Begin")
                        .font(.largeTitle.bold())
                    Text("Please review and accept our Terms of Use and Privacy Policy to continue.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button {
                        onShowTerms()
                    } label: {
                        Label("View Terms", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        onShowPrivacy()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    .buttonStyle(.bordered)
                }

                Toggle("I agree to the Terms of Use and Privacy Policy", isOn: $agree)
                    .toggleStyle(.switch)
                    .padding(.top, 8)

                Button {
                    onAccept()
                } label: {
                    Label("Agree & Continue", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!agree)

                Spacer(minLength: 8)
            }
            .padding()
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
