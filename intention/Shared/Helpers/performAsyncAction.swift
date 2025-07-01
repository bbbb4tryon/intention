//
//  performAsyncAction.swift
//  intention
//
//  Created by Benjamin Tryon on 7/1/25.
//

import Foundation

@MainActor
func performAsyncAction(_ action: @escaping () async throws -> Void) {
    Task {
        do { try await action()
        } catch {
            debugPrint("FocusSessionVM error: \(error)")
            self.lastError = error  // Save for UI overlay
        }
    }
}
