//
//  DynamicMessageAndActionArea.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

struct DynamicMessageAndActionArea: View {
    @ObservedObject var viewModel: FocusSessionVM
    let fontTheme: AppFontTheme     // Pass directly, is an AppStorage value
    let palette: ScreenStylePalette      // Pass directly, is an AppStorage value
    
    // Define sheet closure property, from parent (FocusSessionActiveV) to trigger logic
    //  The closure takes no arguments and returns nothing
    let onRecalibrateNow: () -> Void
    
    var body: some View {
        
        VStack(spacing: 15){
            if viewModel.showRecalibrate {
                recalibrationPromptView
            } else if viewModel.tiles.count == 2 && viewModel.currentSessionChunk == 1 && viewModel.phase == .finished {
                firstChunkCompletedView
            } else if viewModel.phase == .running {
                // General state: 1st or 2nd tile are active, both countdown OverallSession are running
                sessionInProgressView
                
            } else if viewModel.tiles.count < 2 {
                addIntentionPromptView
                
            } else if viewModel.tiles.count == 2 && viewModel.phase == .notStarted {
                
                beginSessionPromptView
            }
        }   // End of Message and Action Area
        .padding(.horizontal)   // Padding for entire section
        .animation(.default, value: viewModel.phase) // Animate phase changes
        .animation(.default, value: viewModel.tiles.count) // Animate tile count changes
        
    }
    
    private var recalibrationPromptView: some View {
        VStack {
            Text.styled("Session complete! Ready for recalibration?", as: .header, using: fontTheme, in: palette)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            // if yes, send to recalibration; if no, send back to text input screen
            
            HStack {
                Button("Recalibrate Now"){  // <- button acknowledges prompt; sheet presented logic at bottom of FocusSessionActiveV
                    onRecalibrateNow()
                    debugPrint("Recalibrate model presented?")
                }.mainActionStyle()
                
                Button("Start a new session"){
                    viewModel.showRecalibrate = false   // Dismiss the sheet
                    // Reset VM and clear tiles
                    Task {  await viewModel.resetSessionStateForNewStart()  }
                }.notMainActionStyle()
            }
        }
        .padding()
    }
    
    private var firstChunkCompletedView: some View {
        VStack {
            // State: First 20-min chunk completed, Overall Session paused
            Text.styled("Completed the first intended item!", as: .header, using: fontTheme, in: palette)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            
            Text("Ready to focus on your next intention for 20 minutes?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            Button("Start Next Intention")
            {
                viewModel.showRecalibrate = false   // Dismisses the sheet
                Task {
                    guard ((try? await viewModel.startCurrent20MinCountdown()) != nil) else {
                        throw ActiveSessionError.submitFailed
                    }    // Start the countdown for the second chunk
                }
                debugPrint("NextIntention button pressed.")
                print("`Start Next Intention` button pressed")
            }.mainActionStyle()
            
            
            Button("End Session Early") {
                Task {
                    guard ((try? await viewModel.resetSessionStateForNewStart()) != nil) else {
                        throw ActiveSessionError.submitFailed
                    }
                }
                debugPrint("EndSession button pressed, User ended session early.")
                print("Session ended early.")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.red)
            .tint(.red)
        }
    }
    
    private var sessionInProgressView: some View {
        Text("Session in progress...")
            .foregroundStyle(.gray)
            .animation(.easeInOut.delay(0.1))
    }
    private var addIntentionPromptView: some View {
        // Initial state:   0 or 1 tile added only
        Text("Add your first (or second) intention above")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        
    }
    private var beginSessionPromptView: some View {
        Text("Enter Your Intention and Press `\(viewModel.tiles.count < 2 ? "Add" : "Begin")`")
            .font(.caption)
            .foregroundStyle(.gray)
            .multilineTextAlignment(.center)
    }
}
