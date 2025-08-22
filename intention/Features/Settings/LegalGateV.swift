//
//  LegalGateV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//

import SwiftUI

struct LegalGateV: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(LegalKeys.acceptedVersion) private var acceptedVersion: Int = 0
    @AppStorage(LegalKeys.acceptedAtEpoch) private var acceptedAtEpoch: Double = 0

    @State private var agree = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to intendly")
                    .font(.title.bold())

                Text("Please review and accept our Terms and Privacy Policy to continue.")

                HStack(spacing: 12) {
                    Button("View Terms") { showTerms = true }
                    Button("View Privacy") { showPrivacy = true }
                }

                Toggle("I agree to the Terms of Use and Privacy Policy", isOn: $agree)
                    .toggleStyle(.switch)

                Button(role: .none) {
                    acceptedVersion = LegalConfig.currentVersion
                    acceptedAtEpoch = Date().timeIntervalSince1970
                    dismiss()
                } label: {
                    Text("Agree & Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!agree)

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showTerms) {
                NavigationStack {
                    LegalDocV(
                        title: "Terms of Use",
                        markdown: MarkdownLoader.load(named: LegalConfig.termsFile)
                    )
                }
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationStack {
                    LegalDocV(
                        title: "Privacy Policy",
                        markdown: MarkdownLoader.load(named: LegalConfig.privacyFile)
                    )
                }
            }
        }
    }
}
