//
//  LegalSupportV.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//

import SwiftUI

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
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("⚠️ \(base).md: failed to read: \(error)")
            return ""
        }
    }
}

// MARK: - Reusable Markdown screen
struct LegalDocV: View {
    let title: String
    let markdown: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let attr = try? AttributedString(markdown: markdown) {
                    Text(attr).textSelection(.enabled)
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
