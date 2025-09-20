//
//  FocusSessionActiveV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

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
enum ActiveSessionError: Error, Equatable, LocalizedError {
    case submitFailed, sessionAlreadyRunning

    var errorDescription: String? {
        switch self {
        case .submitFailed: return "Submit failed"
        case .sessionAlreadyRunning: return "A session is already running."
        }
    }
}

/// MembershipSheetV modal sheet presentation handling enum
enum ActiveSheet: Equatable { case none, membership }

/// The main view for running a focus session, accepting two intention tiles of text inpit
/// Displays countdown timer, text input for intention tiles, recalibration sheet
struct FocusSessionActiveV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var memVM: MembershipVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityDifferentiateWithoutColor) private
        var diffNoColor

    /// Session state and session logic container
    @ObservedObject var focusVM: FocusSessionVM

    /// Recalibration session VM (ObservedObject for ViewModel owned by parent)
    @ObservedObject var recalibrationVM: RecalibrationVM

    /// Gated behind interaction and state
    @FocusState private var intentionFocused: Bool  // manages both focus to textfield AND return from background
    @State private var showValidation: Bool = false
    @State private var showEmptySubmitError = false

    /// Live validation when there’s text and the messages aren’t empty
    private var shouldShowValidation: Bool {
        // Live validation for non-empty text (length, symbols, etc)
        let liveIssues =
            !focusVM.tileText.isEmpty
            && !focusVM.tileText.taskValidationMessages.isEmpty
        return (focusVM.phase == .idle) && (liveIssues || showEmptySubmitError)
    }

    // Keeps call sites short and every string goes through the style system - provides a closure that returns a `LocalizedStringKey` using `theme.styledText(_:as:in:)`
    /// Theme hooks
    private let screen: ScreenName = .homeActiveIntentions
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }

    // Convenience
    private var isInputActive: Bool {
        focusVM.phase != .running && focusVM.tiles.count < 2
    }
    private var vState: ValidationState {
        let msgs = focusVM.tileText.taskValidationMessages
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }

    var body: some View {
        ZStack {
            ScrollView {
                /// Allows content to breath on small screens
                Page(top: 4, alignment: .center) {
                    StatsSummaryBar()
                        .padding(.top, 4)

                    // Text input + validation
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .leading) {
                            if focusVM.tileText.isEmpty {
                                T("Add intention", .caption)
                                    //  .padding(.horizontal, 16)
                                    .disabled(focusVM.phase != .idle)  // FIXME: does this block editing while running?
                                    .focused($intentionFocused)
                                    .onSubmit { intentionFocused = false }  // Allows dismiss on return
                                    .scrollDismissesKeyboard(.immediately)  // NOTE: scrollview dismiss
                                    //  .submitLabel(.done)
                                    //  .allowsHitTesting(false)                    // so taps go into the TextField
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                intentionFocused = false
                                            }
                                        }
                                    }
                                // if shouldShowValidation {
                                //  ValidationCaption(state: .invalid(messages: focusVM.tileText.taskValidationMessages), palette: p)
                                // }
                            }

                            TextField("", text: $focusVM.tileText)
                                // FIXME: is this correcting the validation messages (103-110 with 116-118)?
                                .focused($intentionFocused)
                                .submitLabel(.done)
                                // only shows the “empty/spaces” error when the user actually taps Done with blank input
                                .onSubmit {
                                    let trimmed = focusVM.tileText
                                        .trimmingCharacters(
                                            in: .whitespacesAndNewlines
                                        )
                                    if trimmed.isEmpty {
                                        showEmptySubmitError = true
                                        return
                                    }
                                    showEmptySubmitError = false
                                    Task {
                                        try? await focusVM
                                            .addTileAndPrepareForSession(
                                                focusVM.tileText
                                            )
                                    }
                                }

                                .validatingField(state: vState, palette: p)
                                .disabled(!isInputActive)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.sentences)
                            if shouldShowValidation {
                                ValidationCaption(
                                    state: .invalid(
                                        messages: focusVM.tileText
                                            .taskValidationMessages
                                    ),
                                    palette: p
                                )
                            }

                            // Guidance + Messages (no Add/Begin here)
                            DynamicMessageAndActionArea(
                                focusVM: focusVM,
                                onRecalibrateNow: {
                                    focusVM.showRecalibrate = true
                                }
                            )
                            .environmentObject(theme)

                            // Centered countdown
                            if focusVM.phase == .running {
                                DynamicCountdown(
                                    fVM: focusVM,
                                    palette: p,
                                    progress: Double(focusVM.countdownRemaining)
                                        / Double(
                                            TimerConfig.current.chunkDuration
                                        )
                                )
                                .frame(maxWidth: .infinity)  // centers fixed-size content
                            }
                        }
                        // Drop focus when we start running or when we leave the screen
                        .onChange(of: focusVM.phase) { phase in
                            if phase == .running { intentionFocused = false }
                        }
                        .onDisappear { intentionFocused = false }
                    }
                    .background(p.background.ignoresSafeArea())
                    //                    .ignoresSafeArea(.keyboard, edges: .bottom)         //FIXME: Remove this if keyboard gets weird lifting content
                    .disabled(focusVM.phase != .idle)  //FIXME: Remove this if keyboard toolbar becomes inert // Text field inactive once running
                }

                // Sheets
                //            .sheet(isPresented: $focusVM.showRecalibrate) {
                //                RecalibrationV(vm: recalibrationVM)
                //                // FIXME: which looks better:
                //                    .presentationDetents([.large])  // avoids "medium" overlap
                //                    .presentationDragIndicator(.visible)
                //                    .ignoresSafeArea()              // if the sheet edges are tight
                //                // FIXME: or this at line 150, replacing current:
                //                // Bottom inset: only when sheet is NOT showing
                ////                    .safeAreaInset(edge: .bottom) {
                ////                        if !focusVM.showRecalibrate { BottomComposer }
                ////                    }
                //            }
                // FIXME: or this option is a "no overlap at all" look
                .fullScreenCover(isPresented: $focusVM.showRecalibrate) {
                    RecalibrationV(vm: recalibrationVM)
                }

                // Bottom inset: slots + single CTA
                .safeAreaInset(edge: .bottom, spacing: 10) { BottomComposer }
                //  .safeAreaInset(edge: .bottom) {  if !focusVM.showRecalibrate { BottomComposer }}
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .init("dev.openRecalibration")
            )
        ) { _ in
            focusVM.showRecalibrate = true
        }
    }

    // MARK: Bottom composer
    @ViewBuilder
    private var BottomComposer: some View {
        let completedSlotIndex: Int? =
            (focusVM.currentSessionChunk >= 1) ? 1 : nil  // slots = [second, first]
        VStack(spacing: 10) {
            // two rows, bottom fills first
            ForEach(0..<slots.count, id: \.self) { idx in
                let txt = slots[idx]
                let filled = (txt?.isEmpty == false)
                let tileIsCompleted = (completedSlotIndex == idx)
                let slotBg =
                    filled ? p.surface.opacity(0.9) : p.surface.opacity(0.35)

                ZStack {
                    // card
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(slotBg)
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .stroke(p.border, lineWidth: 1)
                        )
                        .frame(height: 50)
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                        )
                        .overlay {
                            if diffNoColor && !filled {
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                                .stroke(
                                    style: StrokeStyle(lineWidth: 1, dash: [5])
                                )
                                .foregroundStyle(p.border)
                            }
                        }

                    // content
                    if let text = txt, !text.isEmpty {
                        HStack(spacing: 8) {
                            Text(text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .foregroundStyle(
                                    tileIsCompleted
                                        ? p.text.opacity(0.55) : p.text
                                )

                            if tileIsCompleted {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(p.accent)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(p.accent.opacity(0.6))
                            .accessibilityHidden(true)
                    }
                }
                .opacity(tileIsCompleted ? 0.7 : 1.0)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    filled
                        ? (tileIsCompleted
                            ? "Intention completed" : "Intention")
                        : "Empty slot"
                )
                .accessibilityHint(
                    filled ? "" : "Add an intention above, then press Add."
                )
            }

            Button {
                Task { await focusVM.handlePrimaryTap() }
            } label: {
                T(ctaTitle, .action).monospacedDigit()
            }
            .primaryActionStyle(screen: screen)
            .accessibilityIdentifier("primaryCTA")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.thinMaterial)
        .animation(.easeInOut(duration: 0.2), value: focusVM.tiles)
    }

    // KEEP "vm" so type checker isn't tripped up as it might be with 'focusVM' naming
    @ViewBuilder
    private func tileCell(for slot: Int) -> some View {
        if let t = tile(at: slot) {  // FIXME: rename t to cellContents
            let vm = focusVM
            TileCell(tile: t)
                .opacity(vm.thisTileIsCompleted(t) ? 0.55 : 1.0)
                .overlay(alignment: .topLeading) {
                    if vm.thisTileIsCompleted(t) {
                        Image(systemName: "checkmark.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .green)
                            .imageScale(.large)
                            .padding(6)
                    }
                }
        } else {
            EmptyView()
        }
    }

    private var ctaTitle: String {
        if focusVM.tiles.count < 2 { return "Add" }
        if focusVM.phase == .idle { return "Begin" }
        if focusVM.phase == .finished && focusVM.currentSessionChunk == 1 {
            return "Next"
        }
        return "Begin"
    }

    private var slots: [String?] {
        let first =
            focusVM.tiles.indices.contains(0) ? focusVM.tiles[0].text : nil
        let second =
            focusVM.tiles.indices.contains(1) ? focusVM.tiles[1].text : nil
        return [second, first]
    }

    private func tile(at slot: Int) -> TileM? {
        let tileInto = focusVM.tiles
        guard (0..<tileInto.count).contains(slot) else { return nil }
        return tileInto[slot]
    }
}
// Hydrate the VM: tiles, phase, chunk index, and remaining time

// MARK: - Preview
#if DEBUG
    #Preview("Focus") {
        PreviewWrapper {
            FocusSessionActiveV(
                focusVM: PreviewMocks.focusSession,
                recalibrationVM: RecalibrationVM(haptics: NoopHapticsClient())
            )
            .previewTheme()
        }
    }
#endif
