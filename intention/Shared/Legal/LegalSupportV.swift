//
//  LegalSupportV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//
import SwiftUI
import UIKit

// MARK: - Persisted acceptance state
struct LegalKeys {
    static let acceptedVersion = "legal.acceptedVersion"
    static let acceptedAtEpoch = "legal.acceptedAtEpoch"
}

enum LegalConsent {
    static func needsConsent(currentVersion: Int = LegalConfig.currentVersion) -> Bool {
        UserDefaults.standard.integer(forKey: LegalKeys.acceptedVersion) < currentVersion
    }
    static func recordAcceptance(currentVersion: Int = LegalConfig.currentVersion) {
        UserDefaults.standard.set(currentVersion, forKey: LegalKeys.acceptedVersion)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: LegalKeys.acceptedAtEpoch)
    }
    /// DEBUG: clear all acceptance so the sheet will show again
    static func clearForDebug() {
        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedVersion)
        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedAtEpoch)
    }
}

// MARK: - File config (do NOT include .md)
/// Gate logic checks acceptedVersion < currentVersion. After you ship an update with currentVersion = 2, any user who previously accepted version 1 will see the legal sheet again on next launch.
enum LegalConfig {
    static let currentVersion = 1               // "bumping" this (1 to 2 to 3)
    static let termsFile   = "termsMarkdown"
    static let privacyFile = "privacyMarkdown"
    static let medicalFile = "medicalMarkdown"
}

// MARK: - Markdown loader (accepts base name; always reads .md from bundle)
enum MarkdownLoader {
    static func load(named name: String) -> String {
        let base: String = name.lowercased().hasSuffix(".md") ? String(name.dropLast(3)) : name
        guard let url = Bundle.main.url(forResource: base, withExtension: "md") else {
            print("⚠️ Could not find \(base).md in the main bundle.")
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
            print("⚠️ \(base).md: failed to read: \(error)")
            return ""
        }
    }
}

// MARK: Markdown formatting helper
/// Simple, nice-looking Markdown renderer using UITextView with global paragraph & link styles.
/// - No editing; supports selection, links, Dynamic Type, and dark mode.
/// - Style knobs are at the top (spacing, fonts).
struct MarkdownTextView: UIViewRepresentable {
    let markdown: String
    let textColor: UIColor
    let linkColor: UIColor
    let backgroundColor: UIColor
    
    // Global style “dials”
    var baseFont: UIFont = .systemFont(ofSize: 17)            // body
    var h1Font: UIFont = .systemFont(ofSize: 28, weight: .semibold)
    var h2Font: UIFont = .systemFont(ofSize: 22, weight: .semibold)
    var h3Font: UIFont = .systemFont(ofSize: 18, weight: .semibold)
    var lineSpacing: CGFloat = 2
    var paragraphSpacing: CGFloat = 8
    var listParagraphSpacing: CGFloat = 6
    var contentInset: UIEdgeInsets = .init(top: 24, left: 20, bottom: 24, right: 20)
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false         // let SwiftUI ScrollView handle scrolling
        tv.backgroundColor = backgroundColor
        tv.textContainerInset = contentInset
        tv.adjustsFontForContentSizeCategory = true
        tv.dataDetectorTypes = [.link, .phoneNumber]
        tv.linkTextAttributes = [.foregroundColor: linkColor]
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.accessibilityTraits.insert(.staticText)
        return tv
    }
    
    func updateUIView(_ tv: UITextView, context: Context) {
        tv.backgroundColor = backgroundColor
        tv.linkTextAttributes = [.foregroundColor: linkColor]
        
        // Parse Markdown via AttributedString
        let cleaned = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let swiftAttr = (try? AttributedString(markdown: cleaned)) ?? AttributedString(cleaned)
        let bridged = NSAttributedString(swiftAttr)
        let ns = NSMutableAttributedString(attributedString: bridged)
        
        // Apply global paragraph style
        let para = NSMutableParagraphStyle()
        para.lineSpacing = lineSpacing
        para.paragraphSpacing = paragraphSpacing
        
        ns.addAttributes([
            .paragraphStyle: para,
            .foregroundColor: textColor,
            .font: baseFont
        ], range: NSRange(location: 0, length: ns.length))
        
        // Bump headings if present
        ns.enumerateAttribute(.font, in: NSRange(location: 0, length: ns.length)) { value, range, _ in
            guard let f = value as? UIFont else { return }
            // Heuristic: larger/bold fonts from the Markdown import -> map to fixed sizes.
            switch f.pointSize {
            case 24...: ns.addAttribute(.font, value: h1Font, range: range)
            case 20..<24: ns.addAttribute(.font, value: h2Font, range: range)
            case 17..<20:
                if f.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    ns.addAttribute(.font, value: h3Font, range: range)
                }
            default: break
            }
        }
        
        // Tight list items
        ns.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: ns.length)) { value, range, _ in
            guard let p = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle else { return }
            // crude but effective: if the paragraph contains a bullet/dash, reduce spacing slightly
            let substring = ns.attributedSubstring(from: range).string
            if substring.trimmingCharacters(in: .whitespaces).hasPrefix("-")
                || substring.contains("•") {
                p.paragraphSpacing = listParagraphSpacing
                ns.addAttribute(.paragraphStyle, value: p, range: range)
            }
        }
        
        tv.attributedText = ns
        tv.textColor = textColor
    }
    
    // reports the correct height to SwiftUI so the whole document is visible
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize {
        // Use the proposed width (minus horizontal insets) or fall back to screen width
        let proposedWidth = (proposal.width ?? UIScreen.main.bounds.width)
        let targetWidth = max(0, proposedWidth - (contentInset.left + contentInset.right))
        
        uiView.textContainerInset = contentInset
        uiView.textContainer.size = CGSize(width: targetWidth, height: .greatestFiniteMagnitude)
        uiView.layoutManager.ensureLayout(for: uiView.textContainer)
        
        // Ask the text system how tall it wants to be at this width
        let size = uiView.sizeThatFits(CGSize(width: proposedWidth, height: .greatestFiniteMagnitude))
        // Ensure we at least return the inset’d width
        return CGSize(width: proposedWidth, height: ceil(size.height))
    }
}



// MARK: - Reusable Markdown screen
struct LegalDocV: View {
    let title: String
    let markdown: String
    
    var body: some View {
        ScrollView {
            MarkdownTextView(
                markdown: markdown, textColor: UIColor(Color.black), linkColor: UIColor(Color.blue), backgroundColor: UIColor(Color.white)
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
