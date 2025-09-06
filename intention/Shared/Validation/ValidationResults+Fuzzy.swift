//
//  ValidationResults+Fuzzy.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import Foundation
//
// MARK: - non-fragile assertions and Generic Result Validations
extension String {
    var categoryTitleMessages: [String] {
        var messages: [String] = []
        let trimmedTitle = trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTitle.count > 70 { messages.append("70 character limit.") }
        if trimmedTitle.isEmpty { messages.append("A category title cannot be empty.") }

        let consecutiveCharacterPattern = "([.,?!'#@&-]){3,}"
        if trimmedTitle.range(of: consecutiveCharacterPattern, options: .regularExpression) != nil {
            messages.append("Avoid 3 or more consecutive symbols.")
        }

        let invalidCharacterPattern = "(?i)[^a-z0-9 .,?!#'@()&]"
        let invalidCharacterRegex = try! NSRegularExpression(pattern: invalidCharacterPattern)
        if invalidCharacterRegex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil {
            messages.append("Title contains unsupported characters.")
        }

        return messages
    }

    var taskValidationMessages: [String] {
        var messages: [String] = []
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count > 250 { messages.append("250 character limit.") }
        if trimmed.isEmpty { messages.append("Cannot be empty or just spaces.") }

        let consecutiveCharacterPattern = "(&{3,}|={3,}|<{3,}|>{3,}|\\+{3,}|,{3,}|\\.{4,})"
        let consecutiveCharacterRegex = try! NSRegularExpression(pattern: consecutiveCharacterPattern)
        if consecutiveCharacterRegex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil {
            messages.append("Avoid long runs of special symbols.")
        }

        let invalidCharacterPattern = "[^A-Za-z0-9 .,!?'-@#$%^&*()_+=/\\`~{}\\[\\]|:;\"\\\\]"
        let invalidCharacterRegex = try! NSRegularExpression(pattern: invalidCharacterPattern)
        if invalidCharacterRegex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil {
            messages.append("Contains unsupported characters.")
        }
        return messages
    }
}
