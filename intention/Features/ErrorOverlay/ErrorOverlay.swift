//
//  ErrorOverlay.swift
//  intention
//
//  Created by Benjamin Tryon on 7/1/25.
//

import SwiftUI

// `self.lastError = error` to trigger the ErrorOverlay
struct ErrorOverlay: View {
    @EnvironmentObject var theme: ThemeManager
    let error: Error
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("⚠️ Something went wrong")
                .bold()
            Text(displayMessage(for: error))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Dismiss", action: dismissAction)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
    
    private func displayMessage(for error: Error) -> String {
        let description = error.localizedDescription
        if description == "The operation could not be completed." {
            return "Something went wrong, please try again"
    }
            return description
    }
}

/*
 Currently, error displays FocusSessionError.unexpected or HistoryError.categoryNotFound, etc.
 Meaning enums fall back to String(describing:) so you see FocusSessionError.unexpected or HistoryError.categoryNotFound

 Later: As soon as you add `LocalizedError` with `custom errorDescription`, the nicer user message shows:
 enum HistoryError: LocalizedError {
     case categoryNotFound
     var errorDescription: String? { "The category could not be found. Tile not added." }
 }
 …the overlay will automatically show "The category could not be found. Tile not added." without any changes to the view
 */
