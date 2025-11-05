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
    
    private let screen: ScreenName = .focus // or whichever main screen hosts this overlay
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    
    // --- Local Color Definitions by way of Recalibration ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        ZStack {
            RadialGradient(
                        gradient: Gradient(colors: p.radialBackground.colors),
                        center: p.radialBackground.center,
                        startRadius: p.radialBackground.startRadius,
                        endRadius: p.radialBackground.endRadius
                    )
            .ignoresSafeArea()
        VStack(spacing: 12) {
            Text("⚠️ Something went wrong")
                .bold()
                .foregroundStyle(colorDanger)
            
            // Message: use the theme's text color for readability
            Text(displayMessage(for: error))
                .multilineTextAlignment(.center)
                .foregroundStyle(p.text)
            
            // Use theme's primary CTA/Accent color
            Button("Dismiss", action: dismissAction)
                .buttonStyle(.borderedProminent)
                .tint(p.accent) // Use the theme's accent color for the button
        }
        .padding(20)            // Lots, for visual spacing
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 4)    // softer
        .padding(30)        // Ensures overlay doesn't hug screen edges
    }
}
    
    private func displayMessage(for error: Error) -> String {
        let description = error.localizedDescription
        if description == "The operation could not be completed." {
            return "Please try again"
    }
            return description
    }
}

struct SampleErr: LocalizedError {
    var errorDescription: String? { "sample err" }
}

#if DEBUG
#Preview("Error Overlay (dumb)") {
    ErrorOverlay(
        error: SampleErr(), dismissAction: {}
    )
        .environmentObject(ThemeManager())
        .background(Color.black.opacity(0.1))
}
#endif


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
