//
//  LegalDocV.swift
//  intention
//
//  Created by Benjamin Tryon on 10/22/25.
//

import SwiftUI

// MARK: Reusable Markdown screen
struct LegalDocV: View {
    let title: String
    let markdown: String
    
    var body: some View {
        ScrollView {
            SimpleMarkdownView(
                markdown: markdown
            )
            //            VStack(alignment: .leading, spacing: 16) {
            //                if let attr = try? AttributedString(markdown: markdown) {
            //                    Text(attr).textSelection(.enabled)
            //                } else {
            //                Text(formatted(markdown: markdown)).textSelection(.enabled).tint(Color.blue).frame(maxWidth: .infinity, alignment: .leading)
            //            }
            .frame(maxWidth: 700)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollIndicators(.hidden)
    }
}
