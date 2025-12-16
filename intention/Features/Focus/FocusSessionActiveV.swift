//
//  FocusSessionActiveV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.

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

/// Primary screen. Accepts two intention tiles and runs a 20-min countdown.
/// Hosts validation UI, dynamic messages and the recalibration sheet
struct FocusSessionActiveV: View {
    
    // MARK: Environment
    @EnvironmentObject var theme: ThemeManager

    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var memVM: MembershipVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityDifferentiateWithoutColor) private var diffNoColor
    
    // MARK: View Models
    @ObservedObject var focusVM: FocusSessionVM
    @ObservedObject var recalibrationVM: RecalibrationVM
    
    // MARK: Local UI State
    /// manages both focus to textfield AND return from background
    /// single flag `showValidation`controls when to show validation checks
    @FocusState private var intentionFocused: Bool
    @State private var showValidation: Bool = false
    @State private var isBusy = false
    @State private var isShowingRecalibrationToDebug = false
    private let minDesiredHeight: CGFloat = 40
//    @State private var isShowingOrganizerOverlayToDebug = false
    
    /// Theme hooks
    private let screen: ScreenName = .focus
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions for Focus ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    // MARK: - Computed helpers -
    private var isInputActive: Bool {
        focusVM.phase != .running && focusVM.tiles.count < 2
    }
    
    private var vState: ValidationState {
        // Until first submit, stay neutral - charcoal border, no caption)
        guard showValidation else { return .none }
        let msgs = focusVM.tileText.taskValidationMessages
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    
    private var upperComposer: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatsSummaryBar()
            
            if isInputActive {
                // onSubmit and primaryCTA both call the same VM method handlePrimaryTap() -> "same funnel"
                // lifted .placeholder / .caption contrast in ThemeManager and that boots this textfield
                
                IntentionField(
                    p: p,
                    text: $focusVM.tileText,
                    showValidation: $showValidation,
                    vState: vState,
                    isEnabled: isInputActive
                ) { trimmed in
                    Task {
                        do {

                            _ = try await focusVM.handlePrimaryTap(validatedInput: trimmed)
                        } catch {
                            debugPrint(
                                "[FocusSessionActiveV] handlePrimaryTap(from IntentionField) failed: \(error)"
                            )
                        }
                    }
                }
            }
            messageSection
            countdownSection
        }
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        // Guidance  Messages (no Add/Begin here)
        DynamicMessageAndActionArea(
            onRecalibrateNow: { focusVM.showRecalibrate = true }
        )
        .environmentObject(focusVM)
        .padding(.top, 8)
        .environmentObject(theme)
    }
    
    // MARK: - DynamicCountdown
    //  Centered countdown (its internal own logic self-selects paused/running visuals
    //      inside it, `isActive` includes .running  .paused
    //      In .paused, it draws the clipped overlay  "Paused"; in .running, it draws the unwinding pie  time
    //      The tap target persists across both states, thanks to .onTapGesture { handleTap() }.
    private var countdownSection: some View {
        DynamicCountdown(
            palette: p,
            progress: Double(focusVM.countdownRemaining) / Double( TimerConfig.current.chunkDuration )
        )
        .environmentObject(focusVM)
        .padding(.top, 28)  // separates from Stats and messages
        .frame(maxWidth: .infinity)  // centers fixed-size content
        .frame(minHeight: 320)          // reserves vertical space so it dominates the section
        .contentShape(Rectangle())      // keeps taps clean in the area
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
    
    // MARK: - Primary CTA helpers
    /// Icon for the primary CTA button
    ///     - Before two tiles: "add"
    ///     - When ready to begin: "play"
    private var primaryCTAIconName: String {
        focusVM.ui_isReadyForBegin ? "play.fill" : "plus.circle"
    }
    
    private var primaryCTALabel: some View {
        HStack {
            Image(systemName: primaryCTAIconName)
            T(focusVM.primaryCTATile, .action)
                .monospacedDigit()
        }
    }
    
    // MARK: Centralized primary-CTA tap handler
    private func handlePrimaryCTATap() {
        showValidation = true
        // For Add flow, enforce validation first; for Begin flow canPrimary already handles phase/tiles.
        if focusVM.tiles.count < 2 && vState.isInvalid {
            return
        }
        
        let trimmed = focusVM.tileText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do { _ = try await focusVM.handlePrimaryTap(validatedInput: trimmed) }
            catch {
                debugPrint("[FocusSessionActiveV] handlePrimaryTap(from primary CTA) failed: \(error)")
                // If you later add focusVM.setError(_:) or similar, plug it in here.
                /* show error overlay? */
            }
        }
        
        focusVM.tileText = ""
        intentionFocused = (focusVM.tiles.count < 2)
        showValidation = false
    }
    
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0){
            ScrollView {
                Page(top: 6, alignment: .center) {
                    
                    upperComposer
                        .padding(.top, 8)
                        .onDisappear { intentionFocused = false }
                        .onAppear { guard !IS_PREVIEW else { return }
                            focusVM.enterIdleIfNeeded()
                            // Auto-focus on first load, if we still can add text
                            intentionFocused = (focusVM.phase != .running && focusVM.tiles.count < 2)
                        }
                    // Drops focus when we start running or when we leave the screen
                        .onChange(of: focusVM.phase) { phase in
                            if phase == .running {
                                intentionFocused = false
                            }
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
        
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        // Single bottom chrome: do NOT add an overlay; this keeps it snug to the tab bar
        .fullScreenCover(isPresented: $focusVM.showRecalibrate) {
            RecalibrationSheetChrome(onClose: {
                recalibrationVM.performAsyncAction {
                    if recalibrationVM.phase == .running || recalibrationVM.phase == .pause {
                        try await recalibrationVM.stop()
                    }
                }
                focusVM.showRecalibrate = false
            }) {
                NavigationStack {
                    RecalibrationV(vm: recalibrationVM, onSkip: {
                        Task { @MainActor in
                            await focusVM.resetSessionStateForNewStart()
                            focusVM.showRecalibrate = false
                        }
                    })
                        .navigationBarHidden(true)          // own chrome owns the close
                }
            }
        }
        .onDisappear {
            if focusVM.showRecalibrate == false {
                recalibrationVM.performAsyncAction {
                    if recalibrationVM.phase == .running || recalibrationVM.phase == .pause {
                        try await recalibrationVM.stop()
                    }
                }
            }
        }
        
    }
    
    // MARK: Bottom composer
    @ViewBuilder
    private var BottomComposer: some View {
        // Two slots; we present [first, second] visual order by using slots[]
        VStack(spacing: 10){
            ForEach(0..<slots.count, id: \.self) { slot in
                TileSlot(
                    text: slots[slot] ?? "",
                    isFilled: (slots[slot]?.isEmpty == false),
                    isCompleted: completionForSlot(slot),
                    isActive: isActiveSlot(slot),
                    /// VM owns
                    isEditable: focusVM.canEditTile(at: slot),
                    p: p,
                    diffNoColor: diffNoColor,
                    onTap: {
                        // only try to edit if there's a tile
                        guard slots[slot] != nil else { return }
                        // vm owns mutation and rules
                        focusVM.beginEditingTile(at: slot)
                        //View owns focus and validation UX
                        showValidation = true
                        intentionFocused = true
                    }
                )
                .environmentObject(theme)
            }
            
            
            Button(
                action: handlePrimaryCTATap
            ) {
                primaryCTALabel
            }
            .primaryActionStyle(screen: screen)
            .contentShape(Rectangle())
            .pulseAura(color: p.accent, active: focusVM.ui_isReadyForBegin || focusVM.phase == .idle)
            .frame(maxWidth: .infinity, minHeight: minDesiredHeight, maxHeight: 48)
            .lineLimit(1)
            .minimumScaleFactor(0.95)
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
}
    
    // MARK: - IntentionField struct
    // keeps "show validation, submit, text" in one location
    private struct IntentionField: View {
        @EnvironmentObject var theme: ThemeManager
        
        let p: ScreenStylePalette
        @Binding var text: String
        @Binding var showValidation: Bool
        let vState: ValidationState
        let isEnabled: Bool
        let onValidatedSubmit: (String) -> Void
        
        @FocusState private var isFocused: Bool
        
        // MARK: - Body
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "",
                    text: $text,
                    prompt: theme.styledText("Add Your Intended Task", as: .caption, in: .focus
                ))
                // set the text color to a dark, contrasting color
                .foregroundStyle(Color.intGreen)
                .focused($isFocused)
                .submitLabel(.done)
                .validatingField(state: vState, palette: p)
                .disabled(!isEnabled)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.sentences)
                .onSubmit { handleSubmit() }
                
                if showValidation, case .invalid = vState {
                    ValidationCaption(state: vState)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onAppear {
                isFocused = isEnabled
            }
            .onChange(of: isEnabled) { enabled in
                if !enabled { isFocused = false }
            }
        }
        
        private func handleSubmit() {
            // commented out was before revalidating off current text
            showValidation = true
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.taskValidationMessages.isEmpty else { return }
            onValidatedSubmit(trimmed)
//            guard !vState.isInvalid else { return }
            
//            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//            onValidatedSubmit(trimmed)
            
            text = ""
            isFocused = isEnabled // re-focus until two tiles
            showValidation = false
        }
    }
    
    //  MARK: - TileSlot struct
    // TileSlot view (compact min height; segment-like look, multi-line text wraps fully,)
    private struct TileSlot: View {
        @EnvironmentObject var theme: ThemeManager
    
        let text: String
        let isFilled: Bool
        let isCompleted: Bool
        let isActive: Bool
        let isEditable: Bool
        let p: ScreenStylePalette
        let diffNoColor: Bool
        let onTap: (() -> Void)?
        
        // Layout constants
        private let hPad: CGFloat = 10
        private let vPad: CGFloat = 8
        private let minDesiredHeight: CGFloat = 40
        
        // --- Local Color Definitions for Focus ---
        private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
        private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
        private let colorDanger = Color.red
        private let colorSuccess = Color.green
        
        // MARK: Computed Helpers
        
        /// Icon logic:
        /// - Completed      → checkmark.circle.fill
        /// - Editable       → pencil.circle
        /// - Default filled → checkmark.circle
        private var trailingIconName: String {
            if isCompleted { return "checkmark.circle.fill" }
            if isEditable { return "pencil.circle" }
            return "checkmark.circle"
        }
        
        // MARK: - Body
        var body: some View {
            let bg = isActive ? p.surfaces : p.surfaces.opacity(0.35)
            let stroke = colorBorder
            
            // MARK: Tiles container
            VStack {
                if isFilled {
                    HStack(alignment: .top, spacing: 8) {
                        theme.styledText(text, as: .tile, in: .focus)
                            .foregroundStyle(p.text)
                        // Tiny leading for multi-line readability
                            .lineSpacing(2)
                        // Allow text to wrap to as many lines as needed
                            .lineLimit(nil)
                        // This allows the Text view to expand vertically while being constrained horizontally
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Fills the button width, actually
                        Spacer(minLength: 8)
                        
                        // Always show a checkmark for filled tiles
                        Image(systemName: trailingIconName)
                            .font(.body)                        // slightly increases size
                            .foregroundStyle(isCompleted ? p.accent : Color.intGreen)   // more vivid than "accent"
                            .accessibilityHidden(true)
                    }
                    .baselineOffset(1)
                    .padding(.horizontal, hPad)
                    .padding(.vertical, vPad)
                } else {
                    // Empty state - no checkmarks yet
                    HStack(alignment: .firstTextBaseline, spacing: 20) {
                        Image(systemName: "text.alignleft")
                            .font(.body)
                            .accessibilityHidden(true)
                        Text("").foregroundStyle(textSecondary)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.vertical, vPad)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
            // subtle lift to separate from page
            .shadow(radius: 0.9,y: 0.9)
            // container handles "local hit area" of edit
            .frame(minHeight: minDesiredHeight)
            // makes the entire rounded tile the hit-test region, not just the icon
            .contentShape(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .allowsHitTesting(isEditable || BuildInfo.isDebugOrTestFlight)
            .onTapGesture { onTap?() }
            .accessibilityAddTraits(isEditable ? .isButton : [])
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                isFilled
                ? (isCompleted ? "Intention completed" : "Intention")
                : "Empty slot"
            )
            .accessibilityHint(
                isEditable
                ? "Tap to edit"
                : (isFilled ? "" : "Add an intention above, then press Add.")
                )
        }
    }
    
#if DEBUG
    @MainActor private extension FocusSessionVM {
        static var preview: FocusSessionVM {
            let vm = FocusSessionVM(previewMode: true, haptics: NoopHapticsClient())
            // In preview, show two tiles and a plausible remaining time
            vm.tiles = [TileM(text: "Write intro"), TileM(text: "Outline section 1")]
            vm.phase = .running                   // UI shows active state
            vm.currentSessionChunk = 0
            vm.countdownRemaining = 17 * 60 + 42  // static value prevents constant updates
            return vm
        }
    }
#endif
    
    
#if DEBUG
    #Preview("Focus (dumb)") {
        let theme = ThemeManager()
        let focus = FocusSessionVM(previewMode: true,
                                   haptics: NoopHapticsClient(),
                                   config: .current)
        let recal  = RecalibrationVM(haptics: NoopHapticsClient())
        
        FocusSessionActiveV(
            focusVM: focus,
            recalibrationVM: recal
        )
        .environmentObject(theme)
        /* readd ONLY if/when everything else is stable */
        /// .canvasCheap()
        .frame(maxWidth: 430)
    }
#endif
    
