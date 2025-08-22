//
//  LegalLinksV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/20/25.
//

import SwiftUI

///
/// When your website is live, swap each Button with:
/// Link("Terms", destination: LegalConfig.termsURL) and Link("Privacy Policy", destination: LegalConfig.privacyURL)
struct LegalLinksV: View {
    @EnvironmentObject var theme: ThemeManager
    
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text("By continuing, you agree to our")
            
            Button("Terms") { showTerms = true }
                .buttonStyle(.plain)
                .underline()
            
            Text("and")
            
            Button("Privacy Policy") { showPrivacy = true }
                .buttonStyle(.plain)
                .underline()
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
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
