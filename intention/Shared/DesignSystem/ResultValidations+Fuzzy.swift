//
//  ResultValidations+Fuzzy.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import Foundation

// MARK: - non-fragile assertions and Generic Result Validations

//  validating length, preventing problem characters
extension String {
    
    var categoryTitleMessages: [String] {
        var messages: [String] = []
        
        let trimmedTitle = trimmingCharacters(in: .whitespacesAndNewlines)
        
        /// Max character - accessibility recommended
        if trimmedTitle.count > 70 {
            messages.append("70 character limit.")
        }
        
        /// Check for length
        if trimmedTitle.isEmpty { messages.append("A category title cannot be empty.")}
        
        /// Check for excessive consecutive special characters
        let consecutiveCharacterPattern = "([.,?!'#@&-]){3,}" // Check for 3 or more consecutive symbols that can mean problems
        if trimmedTitle.range(of: consecutiveCharacterPattern, options: .regularExpression) != nil {
            messages.append("Can't use two consecutive special characters in a row ([.,?!'#@&-]){3,}.")
        }
        
        // Check for invalid characters
        let invalidCharacterPattern = "(?i)[^a-z0-9 .,?!#'@()&]"
        let invalidCharacterRegex = try! NSRegularExpression(pattern: invalidCharacterPattern)
        if invalidCharacterRegex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil {
            messages.append("Titles can't have pairs of hackable symbols")
        }
        
        return messages
    }
        
    var taskValidationMessages: [String] {
        var messages: [String] = []
        
        /// White space and new lines removed
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        
        /// Max character amount
        if trimmed.count > 250 { messages.append("250 character limit")}
        
        /// Cannot be empty or just spaces
        if trimmed.isEmpty { messages.append("Cannot be empty or just spaces")}
        
        /// Limits to amounts of consecutive special characters
        let consecutiveCharacterPattern = "(&{3,}|={3,}|<{3,}|>{3,}|\\+{3,}|,{3,}|\\.{4,})"
        let consecutiveCharacterRegex = try! NSRegularExpression(pattern: consecutiveCharacterPattern)
        if consecutiveCharacterRegex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil {
            messages.append("No hacking: more than 2 questionable symbols banned")
        }
        
        /// Too many weird symbols
        let invalidCharacterPattern = "[^A-Za-z0-9 .,!?'-@#$%^&*()_+=/\\`~{}\\[\\]|:;\"\\\\]" // Example: allows more symbols
        let invalidCharacterRegex = try! NSRegularExpression(pattern: invalidCharacterPattern)
        if invalidCharacterRegex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil {
            messages.append("Task contains too many non-letters and numbers.")
        }
        
        return messages
    }
}
