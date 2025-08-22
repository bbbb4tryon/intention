//
//  MarkdownV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//

import SwiftUI

/// MarkdownV uses Bundle.main.url(forResource:withExtension:) to locate the Markdown file by name and then reads its content into a string
struct MarkdownV: View {
    @State private var markdownContent: String = ""
    let fileName: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
            Text(AttributedString(markdownContent))
                .padding()
        }
    }
        .navigationTitle(fileName.replacingOccurrences(of: "Markdown.md", with: ""))
        .onAppear {
            if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    self.markdownContent = content
                } catch {
                    debugPrint("Failed to read markdown file")
                }
            } else {
                debugPrint("Could not find \(fileName) file in bundle.")
            }
        }
    }
}
