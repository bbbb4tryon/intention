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

/// The main view for running a focus session, accepting two intention tiles of text input
/// Displays countdown timer, text input for intention tiles, recalibration sheet
struct FocusSessionActiveV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var memVM: MembershipVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityDifferentiateWithoutColor) private var diffNoColor
    
    @ObservedObject var focusVM: FocusSessionVM
    @ObservedObject var recalibrationVM: RecalibrationVM
    
    // manages both focus to textfield AND return from background
    //  single flag `showValidation`controls when to show validation checks
    @FocusState private var intentionFocused: Bool
    @State private var showValidation: Bool = false
    @State private var isBusy = false
    
    private var isInputActive: Bool { focusVM.phase != .running && focusVM.tiles.count < 2 }
    
    private var vState: ValidationState {
        // Until first submit, stay neutral - charcoal border, no caption)
        guard showValidation else { return .none }
        let msgs = focusVM.tileText.taskValidationMessages
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    
    /// Theme hooks
    private let screen: ScreenName = .focus
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        VStack(spacing: 0){             // Main VStack to control vertical layout
            // All your content that should appear above the tiles
            // The `ScrollView` should be constrained to the available space
            ScrollView {
                // Allows content to breath on small screens
                Page(top: 6, alignment: .center) {
                    StatsSummaryBar()
                    // FIXME: Page {} may be controlling sizing, see if .frame( should be dropped
                    
                    
                    // Text input + validation
                    VStack(alignment: .leading, spacing: 8) {
                        if isInputActive {
                            // onSubmit and primaryCTA both call the same VM method handlePrimaryTap() -> "same funnel"
                            TextField("", text: $focusVM.tileText, prompt: T("Add Your Intended Task", .caption))
                                .focused($intentionFocused)
                                .submitLabel(.done)
                                .validatingField(state: vState, palette: p) // charcoal until showValidation == true & invalid
                                .disabled(!isInputActive)                   // lock after 2
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.sentences)
                                .onSubmit {
                                    showValidation = true                   // turn validation on
                                    guard vState.isInvalid == false else { return } // stay focused and show message
                                    // Valid -> add
                                    let trimmed = focusVM.tileText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    Task {
                                        do {
                                            _ = try await focusVM.handlePrimaryTap(validatedInput: trimmed)
                                        } catch {
                                            FocusSessionError.unexpected
                                        }
                                    }
                                    focusVM.tileText = ""                   // Clear text field
                                    intentionFocused = (focusVM.tiles.count < 2) // re-focus UNTIL two tiles
                                    showValidation = false                  // reset to neutral for next entry
                                }
                            // Display ValidationCaption BELOW Textfield
                            //      Caption only after first submit AND invalid
                            if showValidation, case .invalid = vState {
                                // Use VState logic for the correct messages
                                ValidationCaption( state: vState, palette: p)
                                //FIXME: USE THIS BELOW, OR KEEP state: vState, palette: p
                                //                                    state: vState.isInvalid ? vState : .invalid(messages: ["Please enter a task, what you intend to do."]),
                                //                                    palette: p
                                
                            }
                        }
                        // Guidance + Messages (no Add/Begin here)
                        DynamicMessageAndActionArea(
                            focusVM: focusVM,
                            onRecalibrateNow: { focusVM.showRecalibrate = true }
                        )
                        .environmentObject(theme)
                        //  Centered countdown (its internal own logic self-selects paused/running visuals
                        //      inside it, `isActive` includes .running + .paused
                        //      In .paused, it draws the clipped overlay + "Paused"; in .running, it draws the unwinding pie + time
                        //      The tap target persists across both states, thanks to .onTapGesture { handleTap() }.
                        DynamicCountdown(
                            fVM: focusVM,
                            palette: p,
                            progress: Double(focusVM.countdownRemaining) / Double( TimerConfig.current.chunkDuration )
                        )
                        .frame(maxWidth: .infinity)  // centers fixed-size content
                    }
                    .padding(.top, 8)
                    .onDisappear { intentionFocused = false }
                    .onAppear {
                        focusVM.enterIdleIfNeeded()
                        // Auto-focus on first load, if we still can add text
                        intentionFocused = (focusVM.phase != .running && focusVM.tiles.count < 2)
                    }
                    // Drops focus when we start running or when we leave the screen
                    .onChange(of: focusVM.phase) { phase in
                        if phase == .running { intentionFocused = false }
                    }
                    
                }
            }
            // This spacer pushes the scrollable content to the top,
            // making space for the BottomComposer at the very bottom.
            Spacer(minLength: 0)
            BottomComposer
            // inside the main VStack, ensuring it sits at the bottom
            // and doesn't interfere with the ScrollView.
            // It will be snug against the bottom of the screen.
        }
        .onChange(of: focusVM.phase) { _ in
            print(focusVM.debugPhaseSummary("phase change"))
        }
        
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        // Single bottom chrome: do NOT add an overlay; this keeps it snug to the tab bar
        .sheet(isPresented: $focusVM.showRecalibrate) {
            NavigationStack {
                RecalibrationV(vm: recalibrationVM)
                    .presentationDetents([.fraction(0.4), .medium])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(false)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
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
        //        // Two slots; we present [second, first] visual order by using slots[]
        //        let completedSlotIndex: Int? = (focusVM.currentSessionChunk >= 1) ? 1 : nil
        VStack(spacing: 10){
            ForEach(0..<slots.count, id: \.self) { slot in
                TileSlot(
                    text: slots[slot] ?? "",
                    isFilled: (slots[slot]?.isEmpty == false),
                    isCompleted: completionForSlot(slot),
                    isActive: isActiveSlot(slot),
                    palette: p,
                    diffNoColor: diffNoColor
                )
            }
            
            
            Button {
                showValidation = true
                // For Add flow, enforce validation first; for Begin flow canPrimary already handles phase/tiles.
                if focusVM.tiles.count < 2 && vState.isInvalid { return }
                let trimmed = focusVM.tileText.trimmingCharacters(in: .whitespacesAndNewlines)
                Task {
                    do { _ = try await focusVM.handlePrimaryTap(validatedInput: trimmed) }
                    catch { /* show error overlay if desired */ }
                }
                focusVM.tileText = ""
                intentionFocused = (focusVM.tiles.count < 2)
                showValidation = false
            } label: {
                T(focusVM.primaryCTATile, .action).monospacedDigit()
            }
            .primaryActionStyle(screen: screen)
            .frame(maxWidth: .infinity)
            .disabled(!focusVM.canPrimary)
            .accessibilityIdentifier("primaryCTA")
        }
        
        .padding(.top, 12)
        /// tile and begin/add container controls
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: focusVM.tiles)
    }
    
    // MARK: Slot helpers
    /// Visual order = [first, second]
    private var slots: [String?] {
        let first = focusVM.tiles.indices.contains(0) ? focusVM.tiles[0].text : nil
        let second = focusVM.tiles.indices.contains(1) ? focusVM.tiles[1].text : nil
        return [first, second]
    }
    
    /// Completed check uses VM’s persisted logic so it survives navigation/app relaunch
    private func completionForSlot(_ slot: Int) -> Bool {
        guard focusVM.tiles.indices.contains(slot) else { return false }
        return focusVM.thisTileIsCompleted(focusVM.tiles[slot])
    }
    
    /// Active = white; inactive = brown/gray (segment look)
    private func isActiveSlot(_ slot: Int) -> Bool {
        // 1) Before any tiles exist, guide the user by highlighting Tile 1
        if slot == 0 && !focusVM.tiles.indices.contains(0) { return true }
        
        let firstCompleted  = completionForSlot(0)
        let secondCompleted = completionForSlot(1)
        
        switch slot {
        case 0:
            // 2) Keep tile 1 active until completed
            return focusVM.tiles.indices.contains(0) ? !firstCompleted : true
        case 1:
            // Active after first completes, until second completes
            guard focusVM.tiles.indices.contains(1) else { return false }
            return firstCompleted && !secondCompleted
        default:
            return false
        }
    }
}

// MARK: TileSlot view (compact min height; segment-like look, multi-line text wraps fully,)

private struct TileSlot: View {
    @EnvironmentObject var theme: ThemeManager
    let text: String
    let isFilled: Bool
    let isCompleted: Bool
    let isActive: Bool
    let palette: ScreenStylePalette
    let diffNoColor: Bool
    
    // Layout constants
    private let hPad: CGFloat = 10
    private let vPad: CGFloat = 8
    private let minDesiredHeight: CGFloat = 1
    
    var body: some View {
        let bg = isActive ? palette.surface : palette.surface.opacity(0.35)
        let stroke = palette.border
        
        // MARK: - tiles container
        VStack {
            if isFilled {
                HStack(alignment: .top, spacing: 8) {
                    theme.styledText(text, as: .tile, in: .focus)
                        .foregroundStyle(palette.text)
                    // Allow text to wrap to as many lines as needed
                        .lineLimit(nil)
                    // This allows the Text view to expand vertically while being constrained horizontally
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Fills the button width, actually
                    Spacer(minLength: 8)
                    
                    // Always show a checkmark for filled tiles
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.body)                        // slightly increases size
                        .foregroundStyle(palette.success)   // more vivid than "accent"
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
            } else {
                // Empty state - no checkmarks yet
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    Image(systemName: "text.alignleft").font(.body).accessibilityHidden(true)
                    Text("").foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(stroke, lineWidth: 1)
        )
        //        .frame(minHeight: minDesiredHeight, alignment: .center)
        //    }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFilled ? (isCompleted ? "Intention completed" : "Intention") : "Empty slot")
        .accessibilityHint(isFilled ? "" : "Add an intention above, then press Add.")
    }
}



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
