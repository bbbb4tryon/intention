//
//  ValidationState.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import Foundation

enum ValidationState: Equatable {
    case none
    case valid
    case invalid(messages: [String])

    var isInvalid: Bool {
        if case .invalid = self { return true } else { return false }
    }
    var message: String? {
        if case .invalid(let msgs) = self { return msgs.joined(separator: " ") } else { return nil }
    }
}
