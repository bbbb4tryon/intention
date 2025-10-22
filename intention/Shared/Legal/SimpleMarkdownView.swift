//
//  SimpleMarkdownView.swift
//  intention
//
//  Created by Benjamin Tryon on 10/22/25.
//

import SwiftUI

/// Renders a very simple "paragraphs only" view from Markdown input.
/// - Strips markdown formatting (headers, lists, emphasis, code ticks, links),
///   collapses blank lines, and shows paragraphs with uniform spacing.
struct SimpleMarkdownView: View {
    let markdown: String
    
    // Layout “dials”
    var h1Font: Font = .title.weight(.semibold)
    var h2Font: Font = .title2.weight(.semibold)
    var h3Font: Font = .headline
    var bodyFont: Font = .body
    
    var h1Top: CGFloat = 4, h1Bottom: CGFloat = 8
    var h2Top: CGFloat = 12,h2Bottom: CGFloat = 6
    var h3Top: CGFloat = 10, h3Bottom: CGFloat = 4
    var paragraphSpacing: CGFloat = 10
    var horizontalPadding: CGFloat = 20
    var verticalPadding: CGFloat = 24
    
    private var blocks: [Block] { Self.parse(markdown: markdown) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blocks.indices, id:\.self) { i in
                let block = blocks[i]
                switch block {
                case .h1(let t):
                    Text(t)
                        .font(h1Font)
                        .padding(.top, h1Top)
                        .padding(.bottom, h1Bottom)
                case .h2(let t):
                    Text(t)
                        .font(h2Font)
                        .padding(.top, h2Top)
                        .padding(.bottom, h2Bottom)
                case .h3(let t):
                    Text(t)
                        .font(h3Font)
                        .padding(.top, h3Top)
                        .padding(.bottom, h3Bottom)
                case .p(let p):
                    Text(p)
                        .font(bodyFont)
                        .padding(.bottom, paragraphSpacing)
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }
}

// MARK: - Parser
extension SimpleMarkdownView {
    enum Block { case h1(String), h2(String), h3(String), p(String) }

    static func parse(markdown: String) -> [Block] {
        // Normalize endings and strip BOM
        var s = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("\u{FEFF}") { s.removeFirst() }

        // Build blocks
        var blocks: [Block] = []
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            let text = paragraphBuffer.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { blocks.append(.p( stripInline(text) )) }
            paragraphBuffer.removeAll()
        }

        for rawLine in s.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine).trimmingCharacters(in: .whitespaces)

            if line.isEmpty { flushParagraph();continue }

            // Headings only when the line *starts* with hashes
            if let h = headingText(line, level: 1) {
                flushParagraph()
                blocks.append(.h1( stripInline(h) ))
                continue
            }
            if let h = headingText(line, level: 2) {
                flushParagraph()
                blocks.append(.h2( stripInline(h) ))
                continue
            }
            if let h = headingText(line, level: 3) {
                flushParagraph()
                blocks.append(.h3( stripInline(h) ))
                continue
            }

            // Otherwise accumulate paragraph
            paragraphBuffer.append(line)
        }

        flushParagraph()
        return blocks
    }

    /// If line starts with `# ` (repeated `level` times), return text after the marker; else nil.
    private static func headingText(_ line: String, level: Int) -> String? {
        let prefix = String(repeating: "#", count: level) + " "
        return line.hasPrefix(prefix)
            ? String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        : nil
        }

    /// Strip simple inline markdown: **bold**, __bold__, *em*, _em_, `code`, and [text](url) → text
    private static func stripInline(_ s: String) -> String {
        var out = s
        // Links: [text](url) -> text  (manual pass to avoid $1 issues)
        out = stripLinks(out)
        // Remove paired markers by just deleting the markers
        let markers = ["**", "__", "*", "_", "`"]
        for m in markers {
            out = out.replacingOccurrences(of: m, with: "")
        }
        // Collapse internal extra spaces
        while out.contains("  ") { out = out.replacingOccurrences(of: "  ", with: " ") }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Very small link stripper: replaces `[label](...)` with `label`
    private static func stripLinks(_ s: String) -> String {
        var result = ""
        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "[",
               // closeBracket, closeParen
                let closeBracket = s[i...].firstIndex(of: "]"),
               closeBracket < s.index(before: s.endIndex),
                   s[s.index(after: closeBracket)] == "(",
                   let closeParen = s[s.index(after: closeBracket)...].firstIndex(of: ")"){
                    // Append label only
                    let label = s[s.index(after: i)..<closeBracket]
                    result.append(contentsOf: label)
                    i = s.index(after: closeParen)
                    continue
                }
            result.append(s[i])
            i = s.index(after: i)
        }
        return result
    }
}
