//
//  ValidationCaption.swift
//  intention
//
//  Created by Benjamin Tryon on 9/5/25.
//

import SwiftUI

struct ValidationCaption: View {
    let state: ValidationState

    // --- Local Color Definitions for Validations ---
    private let colorDanger = Color.red

    var body: some View {
        if case .invalid (let msgs) = state {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(msgs.joined(separator: " "))
            }
            .font(.footnote)
            .foregroundStyle(colorDanger)
            .accessibilityLabel("Validation error")
            .accessibilityHint(msgs.joined(separator: " "))
            .transition(.opacity.combined(with: .move(edge: .top)))     //TODO: Test this Aim for a 0.2-second transition
        }
    }
}
