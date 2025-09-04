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
    
//    /// Tracks and records consent - inline
//    @State private var showTerms = false
//    @State private var showPrivacy = false
//    
//    /// Small computed property drives legal bar visibility via flag and clean animation
//    private var showLegalBar: Bool {
//        viewModel.tiles.count == 2 && viewModel.phase == .notStarted
//    }
    
    var body: some View {
        /// Get current palette for the appropriate screen
        let p = theme.palette(for: .homeActiveIntentions)
        
        ScrollView {                            /// Allows content to breath on small screens
            Page {
                StatsSummaryBar(palette: p)
                    .padding(.top, 4)
                
                // MARK: - *mounted* Textfield for intention tile text input
                let isInputActive = ( viewModel.phase != .running && viewModel.tiles.count < 2)
                TextField("Enter intention", text: $viewModel.tileText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isInputActive ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.secondary.opacity(isInputActive ? 0.25 : 0.15), lineWidth: 1)
                    )
                    .disabled(!isInputActive)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Intention text")
                    .accessibilityHint("Type your intended task. Add two to begin a session.")
                    .zIndex(1)
                
                
                // MARK: validation ONLY where there ARE messages
                if !viewModel.validationMessages.isEmpty && viewModel.phase != .running {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.validationMessages, id: \.self) { msg in
                            theme.styledText(msg, as: .caption, in: .homeActiveIntentions)
                                .foregroundStyle(.red)      //FIXME: NOT red
                        }
                    }
                    .friendlyAnimatedHelper(viewModel.validationMessages.joined())
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
                        Text(viewModel.tiles.count < 2 ? "Add" : "Begin")
                            .font(.headline).monospacedDigit()
                        //FIXME: blocking the button text no matter what
                        //                        .foregroundStyle( true ? .clear : .accentColor)       /// opacity when inactive
                    }
                    .primaryActionStyle(screen: .homeActiveIntentions)
                    //                .environmentObject(theme)         //FIXME: What is this doing?
                    /// Disable if empty, or 2 tiles already added
                    .disabled(viewModel.tiles.count < 2 && viewModel.tileText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
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
                
                
                // MARK: - Countdown Display (user-facing)
                DynamicCountdown(viewModel: viewModel, palette: p,
                                 progress: Double(viewModel.countdownRemaining) / Double(TimerConfig.current.chunkDuration))
                
                
                // MARK: Add/Begin??
                /// If under two tiles, add the next one. If both are present, begin countdown
                DynamicMessageAndActionArea(
                    viewModel: viewModel,
                    fontTheme: theme.fontTheme, // passing in fontTheme property
                    palette: theme.palette(for: .homeActiveIntentions),
                    onRecalibrateNow: {
                        viewModel.showRecalibrate = true
                    })
                
                // MARK: Tile slots: let content decide height
                VStack(spacing: 8) {                            /// tile spacing
                    ForEach(slotData.indices, id: \.self) { index in
                        TileSlotView(tileText: slotData[index])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .background(p.background.opacity(0.8))
                //            .debugBorder(.green)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(radius: 5)
            }
        }
        .background(p.background.ignoresSafeArea())       /// Paints edge to edge
        .ignoresSafeArea(.keyboard, edges: .bottom)             /// prevent keyboard from shoving whole page up
        
//        .safeAreaInset(edge: .bottom, alignment: .center){
//            VStack(spacing: 8) {
//            if showLegalBar {
//                LegalAffirmationBar(
//                    onAgree: {
//                        if LegalConsent.needsConsent() { LegalConsent.recordAcceptance() }
//                        Task { try? await viewModel.beginOverallSession() }
//                    },
//                    onShowTerms: { showTerms = true },
//                    onShowPrivacy: { showPrivacy = true }
//                )
//                .padding(.horizontal, 16)           /// Page owns margins; give the bar its own margins
//                .transition(.move(edge: .bottom).combined(with: .opacity))
//            }
//            /// Breathing room above tab bar
//            Color.clear.frame(height: 12)
//        }
//    }
//        .animation(.easeIn(duration: 0.2), value: showLegalBar)
        
        /// Legal doc sheets (LegalDocV + MarkdownLoader)
//        .sheet(isPresented: $showTerms) {
//            NavigationStack {
//                LegalDocV(title: "Terms of Use",
//                          markdown: MarkdownLoader.load(named: LegalConfig.termsFile))
//            }
//        }
//        .sheet(isPresented: $showPrivacy) {
//            NavigationStack {
//                LegalDocV(title: "Privacy Policy",
//                          markdown: MarkdownLoader.load(named: LegalConfig.privacyFile))
//            }
//        }
        
        /// Auto-dismiss when MembershipVM flips shouldPrompt to false after successful purchase
        .sheet(isPresented: $membershipVM.shouldPrompt) {
            MembershipSheetV()
                .environmentObject(membershipVM)
                .environmentObject(theme)
        }
        .sheet(isPresented: $viewModel.showRecalibrate){
            RecalibrationV(vm: recalibrationVM)
        }
        
//        .onChange(of: phase) { _, p in if p == .background { Task { await flushPendingSaves() } } }
    }
    
    // MARK: - slotData [String?, String?] ->
    /// Extracted computed property, easier for compiler to parse
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
//    private var isSheetPresented: Bool {
//        activeSheet != .none
//    }
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

