//
//  ValidationState.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import Foundation
/// decide when to surface errors in the view (on submit / CTA) instead of by default while the field is empty
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
