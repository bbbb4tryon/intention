//
//  MarkdownLoader.swift
//  intention
//
//  Created by Benjamin Tryon on 10/22/25.
//

import SwiftUI

// MARK: - Markdown loader (accepts base name; always reads .md from bundle)
enum MarkdownLoader {
    /// Loads a Markdown file from the app bundle by base name.
    /// - Parameter name: The file base name, with or without the `.md` suffix.
    /// - Returns: The normalized Markdown text, or an empty string if not found.
    static func load(named name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.lowercased().hasSuffix(".md") ? String(trimmed.dropLast(3)) : trimmed
        
        // Try locating "<base>.md" in the main bundle
        guard let url = Bundle.main.url(forResource: base, withExtension: "md") else {
            print("⚠️ MarkdownLoader: Missing \(base).md in the main bundle.")
            return ""
        }
        
        do {
            var text = try String(contentsOf: url, encoding: .utf8)
            // normalize endings + strip leading BOM in case an editor added it
            if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
            text = text.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
            return text
        } catch {
            print("⚠️ MarkdownLoader: Failed to read \(base).md - \(error)")
            return ""
        }
    }
}
