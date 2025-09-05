//
//  DynamicMessageAndActionArea.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

struct DynamicMessageAndActionArea: View {
    @ObservedObject var viewModel: FocusSessionVM
    let fontTheme: AppFontTheme         // Pass directly, is an AppStorage value
    let palette: ScreenStylePalette      // Pass directly, is an AppStorage value
    let onRecalibrateNow: () -> Void    // Define sheet closure property, from parent (FocusSessionActiveV) to trigger logic
    private let screen: ScreenName = .homeActiveIntentions
    
    let p: ScreenStylePalette
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .settings)) }
    }
    var body: some View {
        
        VStack(spacing: 24){
            if viewModel.showRecalibrate {
                recalibrationPromptView
            } else if viewModel.tiles.count == 2 && viewModel.currentSessionChunk == 1 && viewModel.phase == .finished {
                firstChunkCompletedView
            } else if viewModel.phase == .running {
                sessionInProgressView
            } else if viewModel.tiles.count < 2 {
                addIntentionPromptView
            } else if viewModel.tiles.count == 2 && viewModel.phase == .notStarted {
                beginSessionPromptView
                
            }
        }   // End of Message and Action Area
        .padding()   // Padding for entire section
        /// Helper reduces motion
        .friendlyAnimatedHelper("\(viewModel.phase) -\(viewModel.tiles.count)")
        .overlay{
            if let error = viewModel.lastError {
                ErrorOverlay(error: error) { viewModel.lastError = nil }
            }
        }
    }
    
    private var recalibrationPromptView: some View {
        VStack(spacing: 12){
            T("""
                Session complete!
                Ready for recalibration?
            """, .title3)
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                /// if yes -> send user to recalibration; if no, send back to text input screen
                Button(T("Recalibrate Now", .action)){  // <- button acknowledges prompt; sheet presented logic at bottom of FocusSessionActiveV
                    onRecalibrateNow()
                    debugPrint("Recalibrate model presented?")
                }
                .primaryActionStyle(screen: screen) /// Replaced .primaryActionStyle(screen: .homeIntentions)
                
                Button(T("Start a new session", .action)){
                    viewModel.performAsyncAction {
                        viewModel.showRecalibrate = false
                        try viewModel.startCurrent20MinCountdown()
                    }
                }
                .secondaryActionStyle(screen: screen)
            }
        }
        .padding()
    }
    
    private var firstChunkCompletedView: some View {
        VStack(spacing: 16) {
            // State: First 20-min chunk completed, Overall Session paused
            T("Completed!", .section)
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.center)
            
            T("Ready to focus on your next intention for 20 minutes?", .title3)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(T("Start Next Intention", .action)  {
                viewModel.performAsyncAction {
                    viewModel.showRecalibrate = false   /// Dismisses the sheet
                    try viewModel.startCurrent20MinCountdown()
                }
            }
            .primaryActionStyle(screen: screen)
            .lineLimit(1)                           /// Part 1 of 2 to prevent line wrapping that increases height
            .minimumScaleFactor(0.9)               /// Part 2 of 2 to prevent line wrapping that increases height
            
                   Button(T("End Session Early", .secondary) {
                viewModel.performAsyncAction {
                    await viewModel.resetSessionStateForNewStart()
                }
            }
            .destructiveActionStyle(screen: screen)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 12)
        }
    }
        
        private var sessionInProgressView: some View {
            T("Session in progress...", .body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        private var addIntentionPromptView: some View {
            // Initial state:   0 or 1 tile added only
            T("Add your first (or second) intention above", .body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            
        }
        private var beginSessionPromptView: some View {
            T("Enter Your Intention and Press `\(viewModel.tiles.count < 2 ? "Add" : "Begin")`", .caption)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
}
