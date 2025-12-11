//
//  PinUnlockSheet.swift
//  intention
//
//  Created by Benjamin Tryon on 12/4/25.
//

import SwiftUI

struct PinUnlockSheet: View {
    var onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pin: String = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Enter PIN") {
                    SecureField("PIN", text: $pin)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                }
                if showError {
                    Text("Incorrect PIN").foregroundStyle(.red)
                }
            }
            .navigationTitle("Debug Access")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unlock") {
                        let p = pin.trimmingCharacters(in: .whitespacesAndNewlines)
                        if p.isEmpty { showError = true; return }
                        let oldShowError = showError
                        onSubmit(p)
                        // Heuristic: if still showing after submit, it failed.
                        Task { @MainActor in
                            try await Task.sleep(nanoseconds: 150_000_000)  // ~0.15s
                            showError = true
                        }
//                        // The router keeps the sheet up when wrong.
//                        DispatchQueue.main.asyncAfter(deadline: .now()  0.1) {
//                            showError = true
//                            if oldShowError { /* keep */ }
//                        }
                    }
                    .disabled(pin.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

