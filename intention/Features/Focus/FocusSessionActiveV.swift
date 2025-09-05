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
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var membershipVM: MembershipVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var phase
    
    /// Session state and session logic container
    @ObservedObject var viewModel: FocusSessionVM
    
    /// Recalibration session VM (ObservedObject for ViewModel owned by parent)
    @ObservedObject var recalibrationVM: RecalibrationVM
    
    /// Keeps call sites short and every string goes through the style system - provides a closure that returns a `LocalizedStringKey` using `theme.styledText(_:as:in:)`
    private var p: ThemePalette { theme.palette(for: .homeActiveIntentions) }
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .homeActiveIntentions)) }
    }
    
    var body: some View {
        ZStack {
            ScrollView {                            /// Allows content to breath on small screens
                Page(top: 4, alignment: .center) {
                    StatsSummaryBar(palette: p)
                        .padding(.top, 4)
                    
                    title
                    
                    textField
                    validations
                    
                    contentTips
                    
                    countdownDisplay
                    
                    // MARK: - *mounted* Textfield for intention tile text input
                    private var textField: String {
                        let isInputActive = ( viewModel.phase != .running && viewModel.tiles.count < 2)
                        let hasValidation = !viewModel.validationMessages.isEmpty && viewModel.phase != .running
                        TextField(T("Enter intention", .placeholder),text: $viewModel.tileText, axis: .vertical)
                            .textFieldStyle(ValidatingFieldStyle(state: viewModel.inputValidationState, palette: p))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isInputActive ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(hasValidation ? theme.palette(for: .homeActiveIntentions).danger : Color.secondary.opacity(isInputActive ? 0.25 : 0.15), lineWidth: 1)
                            )
                            .disabled(!isInputActive)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.sentences)
                            .accessibilityLabel("Intention text")
                            .accessibilityHint("Type your intended task. Add two to begin a session.")
                            .zIndex(1)
                    }
                    
                    // MARK: validation ONLY where there ARE messages
                    private var validations: String {
                        if hasValidation {
                            HStack(spacing: 6){
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(viewModel.validationMessages.joined(separator: ""))
                            }
                            .font(.caption)
                            .foregroundStyle(theme.palette(for: .homeActiveIntentions).danger)
                            .accessibilityLabel("Validation")
                            .accessibilityLiveRegion(.polite)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    //                if !viewModel.validationMessages.isEmpty && viewModel.phase != .running {
                    //                    VStack(alignment: .leading, spacing: 4) {
                    //                        ForEach(viewModel.validationMessages, id: \.self) { msg in
                    //                            theme.styledText(msg, as: .caption, in: .homeActiveIntentions)
                    //                                .foregroundStyle(.red)      //FIXME: NOT red
                    //                        }
                    //                    }
                    //                    .friendlyAnimatedHelper(viewModel.validationMessages.joined())
                    //                }
                    
                    /// Inline disclosure shown only when Begin is relevant
                    
                    //                if viewModel.tiles.count == 2 && viewModel.phase == .notStarted {
                    //                    LegalAffirmationBar(
                    //                        onAgree: { if LegalConsent.needsConsent() { LegalConsent.recordAcceptance() }; Task { try? await viewModel.beginOverallSession() } },
                    //                        onShowTerms: { showTerms = true },
                    //                        onShowPrivacy: { showPrivacy = true }
                    //                    )
                    //                    //                .font(theme.fontTheme.toFont(.footnote))
                    //                    //                .foregroundStyle(.secondary)
                    //                    //                .padding(.horizontal)
                    //                    //                .friendlyAnimatedHelper(viewModel.tiles.count == 2 && viewModel.phase == .notStarted)
                    //                }
                    
                    // MARK: Logic for tiles toward activation
                    /// If under two tiles, add the next one. If both are present, begin countdown
                    private var contentTips: String {
                        DynamicMessageAndActionArea(
                            viewModel: viewModel,
                            fontTheme: theme.fontTheme, // passing in fontTheme property
                            palette: theme.palette(for: .homeActiveIntentions),
                            onRecalibrateNow: {
                                viewModel.showRecalibrate = true
                            }
                        )
                    }

                    // MARK: - Countdown Display (user-facing)
                    private var countdownDisplay: String {
                        DynamicCountdown(viewModel: viewModel, palette: p,
                                         progress: Double(viewModel.countdownRemaining) / Double(TimerConfig.current.chunkDuration))
                    }
                    
                    
                    // MARK: Add/Begin
                    if !viewModel.showRecalibrate && viewModel.phase != .running {
                        Button {
                            Task {
                                do {
                                    if viewModel.tiles.count < 2 {      /// Logic adding tiles
                                        try await viewModel.addTileAndPrepareForSession(viewModel.tileText)
                                        if viewModel.tiles.count == 2 { viewModel.validationMessages.removeAll() }
                                    } else if viewModel.tiles.count == 2 && viewModel.phase == .notStarted { /// Logic starting session
                                        //                                    /// Inline consent: record once, then begin
                                        //                                    if LegalConsent.needsConsent() { LegalConsent.recordAcceptance() }
                                        try await viewModel.beginOverallSession()
                                    }
                                } catch {
                                    debugPrint("[FocusSessionActiveV.Button] error:", error)
                                    viewModel.lastError = error
                                }
                            }
                        } label: {
                            Text(viewModel.tiles.count < 2 ? T("Add", .header) : T("Begin", .header))
                                .monospacedDigit()
                            //FIXME: blocking the button text no matter what
                            //                        .foregroundStyle( true ? .clear : .accentColor)       /// opacity when inactive
                        }
                        .primaryActionStyle(screen: .homeActiveIntentions)
                        //                .environmentObject(theme)         //FIXME: What is this doing?
                        /// Disable if empty, or 2 tiles already added
                        .disabled(viewModel.tiles.count < 2 && viewModel.tileText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    
                }
            }
            .background(p.background.ignoresSafeArea())       /// Paints edge to edge
            .ignoresSafeArea(.keyboard, edges: .bottom)             /// prevent keyboard from shoving whole page up
            
            /// Auto-dismiss when MembershipVM flips shouldPrompt to false after successful purchase
            .sheet(isPresented: $membershipVM.shouldPrompt) {
                MembershipSheetV()
                    .environmentObject(membershipVM)
                    .environmentObject(theme)
            }
            .sheet(isPresented: $viewModel.showRecalibrate){
                RecalibrationV(vm: recalibrationVM)
            }
        }
        
        //        .onChange(of: phase) { _, p in if p == .background { Task { await flushPendingSaves() } } }
        .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    // Two slots, rendered top -> bottom
                    ForEach(Array(slotTextsTopToBottom.enumerated()), id: \.offset) { _, txt in
                        TileSlotView(tileText: txt, palette: p)
                    }

                    // Primary action stays closest to the tab bar for thumb reach
                    Button(viewModel.tiles.count < 2 ? "Add" : "Begin") {
                        Task { await viewModel.primaryTapped() }
                    }
                    .primaryActionStyle(screen: .focus)
                    .disabled(!viewModel.canPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(.thinMaterial) // optional: subtle separation from content
                .animation(.snappy, value: viewModel.tiles) // smooth fill-up
            }
        }
    }

extension FocusSessionActiveV {
    /// Always returns exactly two optionals: [secondSlotTop, firstSlotBottom]
    /// So the **bottom** slot (index 0 in tiles) appears nearest the tab bar.
    var slotTextsTopToBottom: [String?] {
        let first  = viewModel.tiles.indices.contains(0) ? viewModel.tiles[0].text : nil
        let second = viewModel.tiles.indices.contains(1) ? viewModel.tiles[1].text : nil
        return [second, first] // top, bottom  ← this order makes it “fill upward”
    }
}


#Preview("Focus") {
    PreviewWrapper {
        FocusSessionActiveV(
            viewModel: PreviewMocks.focusSession,
            recalibrationVM: RecalibrationVM(haptics: NoopHapticsClient())
        )
        .previewTheme()
    }
}

