//
//  MarkdownLoader.swift
//  intention
//
//  Created by Benjamin Tryon on 8/21/25.
//

import SwiftUI

enum MarkdownLoader {
    static func load(named name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "md") else {
            return "⚠️ Missing \(name).md in app bundle."
        }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? "⚠️ Could not read \(name).md."
    }
}
