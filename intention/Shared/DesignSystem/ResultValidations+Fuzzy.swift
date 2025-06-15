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
    var isValidTitle: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty &&
        trimmed.count < 60 &&   // MARK: - word limit
        trimmed.range(of: "^[A-Za-z0-9 .,!?'-]+$", options: .regularExpression) != nil
    }
}
