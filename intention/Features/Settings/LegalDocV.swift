//
//  LegalDocV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//

import SwiftUI

struct LegalDocV: View {
    let title: String
    let markdown: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let attr = try? AttributedString(markdown: markdown) {
                    Text(attr)
                        .textSelection(.enabled)
                } else {
                    Text(markdown).textSelection(.enabled)
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
