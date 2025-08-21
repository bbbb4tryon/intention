//
//  FocusSessionActiveV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

// FocusSessionActiveV <--> ContentView
// MARK: - Folder Layout (Feature-Based, SwiftUI + UIKit + Actors)

/* Handle, not crash unless app is in danger;
 - fast, well-isolated unit tests
 - performance tests to provide regression coverage of performance-critical regions of code
 - create a test plan to run only the unit tests for a module while developing and debugging that module,
 - a second test plan to run all unit, integration, and UI tests before submitting your app to the App Store
 git commit -m "feat: Add SwiftLint and improve documentation style" -m "This commit adds SwiftLint with a missing_docs rule to enforce documentation standards.
 It also refactors existing comments and documentation to a new, standardized style:
 - Use /// for one-liners.
 - Only use @param and @throws where necessary.
 - Preserve existing clean MARK structures.
 "


 1. Where are resources for quickly getting up to speed EXCEPT apple documentation, which is not my favorite resource to start anything on?
 2. I think a generic test result is best, that is, instead of the test requiring the specific text, I'd rather have test require not empty, not gobbledegook, not malicious and with character and string-length limits or other limits.

 */
import SwiftUI

/// Error types specific to the active session/chunk
enum ActiveSessionError: Error, Equatable {
    case submitFailed, sessionAlreadyRunning
}

/// MembershipSheetV modal sheet presentation handling enum
enum ActiveSheet: Equatable {
    case none, membership
}

/// The main view for running a focus session, accepting two intention tiles of text inpit
/// Displays countdown timer, text input for intention tiles, recalibration sheet
struct FocusSessionActiveV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var membershipVM: MembershipVM
    @Environment(\.dismiss) var dismiss
    
    /// Session state and session logic container
    @ObservedObject var viewModel: FocusSessionVM
    
    /// Recalibration session VM (ObservedObject for ViewModel owned by parent)
    @ObservedObject var recalibrationVM: RecalibrationVM
    
    /// Tracks active sheet for membership prompt
    @State private var activeSheet: ActiveSheet = .none
    
    var body: some View {
        /// Get current palette for the appropriate sceen
        let palette = theme.palette(for: .homeActiveIntentions)
        let chunkSeconds = TimerConfig.current.chunkDuration
        let progress = Double(viewModel.countdownRemaining) / Double(chunkSeconds)

        VStack(spacing: 20){
            
            StatsSummaryBar(palette: palette)
                .frame(height: 56)              // "clamp" the bar height
            
            Spacer()                            // pushes content towards center-top
            
            // MARK: - Textfield for intention tile text input
            TextField("Enter intention", text: $viewModel.tileText, axis: .vertical)    //FIXME: is vertical weird?
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(viewModel.tiles.count == 2 && viewModel.phase == .running)
                .padding(.horizontal)
                .background(viewModel.validationMessages.isEmpty ? palette.accent : Color.red.opacity(0.2))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .lineLimit(3)
            
            // MARK: Data validation messages for textfield
            ForEach(viewModel.validationMessages, id: \.self) { message in
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            
            // MARK: Main Action Inputs
            if !viewModel.showRecalibrate && viewModel.phase != .running {
                Button(action: {
                    Task {
                        do {
                            if viewModel.tiles.count < 2 {      // Logic adding tiles
                                try await viewModel.addTileAndPrepareForSession(viewModel.tileText)
                            } else if viewModel.tiles.count == 2 && viewModel.phase == .notStarted { // Logic starting session
                                try await viewModel.beginOverallSession()
                            }
                        } catch {
                            // View owns the error here
                                        debugPrint("[FocusSessionActiveV.Button] error:", error)
                                        viewModel.lastError = error
                        }
                    }
                }) {
                    Text(viewModel.tiles.count < 2 ? "Add" : "Begin")
                        .font(.headline)
                        .padding(.vertical,8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle( true ? .clear : .accentColor)
                }
                .mainActionStyle(screen: .homeActiveIntentions)
                .environmentObject(theme)
                // Disable if empty, or 2 tiles already aadded
                .disabled(viewModel.tiles.count < 2 && viewModel.tileText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            
            
            // MARK: - Countdown Display (user-facing)
            DynamicCountdown(viewModel: viewModel, palette: palette, progress: progress)
            
            
            // MARK: Main Action Button (Add or Begin)
            /// If under two tiles, add the next one. If both are present, begin countdown
            DynamicMessageAndActionArea(
                viewModel: viewModel,
                fontTheme: theme.fontTheme, // passing in fontTheme property
                palette: theme.palette(for: .homeActiveIntentions),
                onRecalibrateNow: {
                    viewModel.showRecalibrate = true
                })
            
            // Pushes content away from bottom, softer constraints
            Spacer(minLength: 8)
                        
            // MARK: - Fixed-size List: Tile container
            VStack(spacing: 8) {        // tile spacing
                ForEach(slotData.indices, id: \.self) { index in
                    TileSlotView(
                        tileText: slotData[index],
                    )
                }
                .padding(.horizontal)       // Padding for the ForEach content
            }                               // -VStack, tile container end
            .frame(height: 140)             // Shrinks the stack instead of Dynamics
            .background(palette.background.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal)           // Horizonal padding for whole list
            
            Spacer()
        }                                   // -VStack, primary end
        .background(palette.background.ignoresSafeArea(edges: .top))
        .task {
            if membershipVM.shouldPrompt {
                activeSheet = .membership
            }
        }
        .sheet(isPresented: $viewModel.showRecalibrate){
            RecalibrationV(vm: recalibrationVM)
        }
    }
    
    // MARK: - slotData [String?, String?] ->
    //  Extracted computed property, easier for compliler to parse
    /// Returns two tile texts or nil placeholders
    private var slotData: [String?] {
        var data = [String?]()
        for t in 0..<2 {
            if t < viewModel.tiles.count {
                data.append(viewModel.tiles[t].text)
            } else {
                data.append(nil)
            }
        }
        return data
    }
    
    /// Returns whether or not the membership modal sheet is present, in that moment of time
    private var isSheetPresented: Bool {
        activeSheet != .none
    }
}


#Preview("Initial State") {
    PreviewWrapper {
        FocusSessionActiveV(
            viewModel: FocusSessionVM(previewMode: true),
            recalibrationVM: RecalibrationVM()
        )
        .previewTheme()
    }
}
