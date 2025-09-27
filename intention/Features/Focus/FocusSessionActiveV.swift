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
    @FocusState private var intentionFocused: Bool
    @State private var showEmptySubmitError = false
    
    //FIXME: showValidation & isBusy needed?
    @State private var showValidation: Bool = false
    @State private var isBusy = false
    
    /// Theme hooks
    private let screen: ScreenName = .homeActiveIntentions
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    private var isInputActive: Bool { focusVM.phase != .running && focusVM.tiles.count < 2 }
    
    private var vState: ValidationState {
        let msgs = focusVM.tileText.taskValidationMessages
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    /// Live validation when there’s text and the messages aren’t empty
    private var shouldShowValidation: Bool {
        // Live validation for non-empty text (length, symbols, etc)
        let liveIssues = !focusVM.tileText.isEmpty && !focusVM.tileText.taskValidationMessages.isEmpty
        return (focusVM.phase == .idle) && (liveIssues || showEmptySubmitError)
    }
    
    var body: some View {
        VStack(spacing: 0){             // Main VStack to control vertical layout
            // All your content that should appear above the tiles
            // The `ScrollView` should be constrained to the available space
            ScrollView {
                // Allows content to breath on small screens
                Page(top: 6, alignment: .center) {
                    StatsSummaryBar() .frame(maxWidth: .infinity).padding(.top, 6)
                    
                    // Text input + validation
                    VStack(alignment: .leading, spacing: 8) {
                        if isInputActive {
                            TextField("", text: $focusVM.tileText, prompt: T("Add Your Intended Task", .caption))
                                .focused($intentionFocused)
                                .submitLabel(.done)

                                .validatingField(state: vState, palette: p)
                                .disabled(!isInputActive)  // lock after 2
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.sentences)
                                .onSubmit {
                                    let trimmed = focusVM.tileText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { showEmptySubmitError = true; return }
                                    showEmptySubmitError = false
                                    Task { try? await focusVM.addTileAndPrepareForSession(trimmed) }
                                }
                            if shouldShowValidation {
                                ValidationCaption(
                                    state: .invalid(messages: focusVM.tileText.taskValidationMessages.isEmpty && showEmptySubmitError
                                                    ? ["Please enter a task, what you intend to do."]
                                                    : focusVM.tileText.taskValidationMessages),
                                    palette: p
                                )
                            }
                        }
                        // Guidance + Messages (no Add/Begin here)
                        DynamicMessageAndActionArea(
                            focusVM: focusVM,
                            onRecalibrateNow: { focusVM.showRecalibrate = true }
                        )
                        .environmentObject(theme)
                        // Centered countdown
                        if focusVM.phase == .running {
                            DynamicCountdown(
                                fVM: focusVM,
                                palette: p,
                                progress: Double(focusVM.countdownRemaining) / Double( TimerConfig.current.chunkDuration )
                            )
                            .frame(maxWidth: .infinity)  // centers fixed-size content
                        }
                    }
                    .padding(.top, 8)
                    // Drops focus when we start running or when we leave the screen
                    .onChange(of: focusVM.phase) { phase in
                        if phase == .running { intentionFocused = false }
                    }
                    .onDisappear { intentionFocused = false }
                    .onAppear {
                        // Auto-focus on first load, if we still can add text
                        intentionFocused = isInputActive
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
                Task { await focusVM.handlePrimaryTap() }
            } label: {
                T(ctaTitle, .section).monospacedDigit()
            }
            .primaryActionStyle(screen: screen)
            .accessibilityIdentifier("primaryCTA")
        }
        .padding(.top, 12)
        /// tile and begin/add container controls
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.thinMaterial)
        //        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: focusVM.tiles)
    }
    
    // MARK: Slot helpers
    /// Visual order = [second, first]
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
    
    private var ctaTitle: String {
        if focusVM.tiles.count < 2 { return "Add" }
        if focusVM.phase == .idle   { return "Begin" }
        if focusVM.phase == .finished && focusVM.currentSessionChunk == 1 { return "Next" }
        return "Begin"
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
        //
        //        ZStack(alignment: .topLeading) {
        //            RoundedRectangle(cornerRadius: 10, style: .continuous)
        //                .fill(bg)
        //            // interior border line
        //                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(stroke, lineWidth: 1))
        //
        // MARK: - tiles container
        VStack {
            if isFilled {
                HStack(alignment: .top, spacing: 8) {
                    theme.styledText(text, as: .tile, in: .homeActiveIntentions)
                        .foregroundStyle(palette.text)
                    // Allow text to wrap to as many lines as needed
                        .lineLimit(nil)
                    // This allows the Text view to expand vertically while being constrained horizontally
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(palette.accent)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
                .opacity(isCompleted ? 0.75 : 1.0)
            } else {
                // Empty state - compact
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "plus").accessibilityHidden(true)
                    Text("").foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
            }
        }
        // MAYBE A PROBLEM? APPLYING BACKGROUND AND STROKE OR OVERLAY DIRECTLY TO THE CONTAINER?
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(stroke, lineWidth: 1)
        )
        //        .frame(minHeight: minDesiredHeight, alignment: .center)
        //    }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFilled ? (isCompleted ? "Intention completed" : "Intention") : "Empty slot")
        .accessibilityHint(isFilled ? "" : "Add an intention above, then press Add.")
    }
}
//    //KEEP "vm" so type checker isn't tripped up as it might be with 'focusVM' naming
//   @ViewBuilder
//   private func tileCell(for slot: Int) -> some View {
//       if let t = tile(at: slot) {  // FIXME: rename t to cellContents
//           let vm = focusVM
//           TileCell(tile: t)
//               .opacity(vm.thisTileIsCompleted(t) ? 0.55 : 1.0)
//               .overlay(alignment: .topLeading) {
//                   if vm.thisTileIsCompleted(t) {
//                       Image(systemName: "checkmark.circle")
//                           .symbolRenderingMode(.palette)
//                           .foregroundStyle(.green)
//                           .imageScale(.large)
//                           .padding(6)
//                   }
//               }
//       } else {
//           EmptyView()
//       }
//   }

//                let txt = slots[idx]
//                let filled = (txt?.isEmpty == false)
//                let tileIsCompleted = (completedSlotIndex == idx)
//                let slotBg =
//                    filled ? p.accent.opacity(0.9) : p.accent.opacity(0.35)

//                ZStack {
// card
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                        .fill(slotBg)
//                        .overlay(
//                            RoundedRectangle(
//                                cornerRadius: 1,
//                                style: .continuous
//                            )
////                            .debugBackground(.green)
//                            .stroke(p.border, lineWidth: 10)
//                        )
//                        .frame(height: 50)
//                        .contentShape(
//                            RoundedRectangle(
//                                cornerRadius: 1,
//                                style: .continuous
//                            )
//
//                        )
////                        .debugBackground(.green)
//                    // Handles color and checkmark icon within the tiles
//                        .overlay {
//                            if diffNoColor && !filled {
//                                RoundedRectangle(
//                                    cornerRadius: 10,
//                                    style: .continuous
//                                )
//
//                                .stroke(
//                                    style: StrokeStyle(lineWidth: 10, dash: [5])
//                                )
//                                .foregroundStyle(p.border)
//                            }
//                        }
//
//
//                    // Tile 2, Tile 2 text
//                    if let text = txt, !text.isEmpty {
//                        HStack{
//                            Text(text)
//                                .lineLimit(1)
//                                .minimumScaleFactor(0.9)
//                                .foregroundStyle(
//                                    tileIsCompleted
//                                        ? p.text.opacity(0.55) : p.text
//                                )
//
//                            if tileIsCompleted {
//                                Image(systemName: "checkmark.circle")
//                                    .foregroundStyle(p.accent)
//                                    .accessibilityHidden(true)
//                            }
//                        }
//                        .padding(.horizontal, 8)
//                        .frame(alignment: .leading)
//
//
//                    } else {
//                        Image(systemName: "plus")
//                            .font(.headline)
//                            .foregroundStyle(p.accent.opacity(0.6))
//                            .accessibilityHidden(true)
//                    }
////                }
////                .opacity(tileIsCompleted ? 0.7 : 1.0)
////                .accessibilityElement(children: .combine)
////                .accessibilityLabel(
////                    filled
////                        ? (tileIsCompleted
////                            ? "Intention completed" : "Intention")
////                        : "Empty slot"
////                )
////                .accessibilityHint(
////                    filled ? "" : "Add an intention above, then press Add."
////                )
//            }
//
//            Button {
//                Task { await focusVM.handlePrimaryTap() }
//            } label: {
//                T(ctaTitle, .section).monospacedDigit()
//            }
//            .primaryActionStyle(screen: screen)
//            .accessibilityIdentifier("primaryCTA")
//        }
//        /// tile and begin/add container controls
//        .padding(.horizontal, 16)
//        .padding(.bottom, 12)
//        .background(.thinMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//        .animation(.easeInOut(duration: 0.2), value: focusVM.tiles)
//    }






//                            if focusVM.tileText.isEmpty {
//                                T("Add intention", .caption)
////                                    .disabled(focusVM.phase != .idle)  // FIXME: does this block editing while running?
////                                    .focused($intentionFocused)
//                                    .onSubmit { intentionFocused = false }  // Allows dismiss on return
//                                    .scrollDismissesKeyboard(.immediately)  // NOTE: scrollview dismiss
//                                    //  .submitLabel(.done)
//                                    //  .allowsHitTesting(false)                    // so taps go into the TextField
//
//                                /*
//                                 possible modifiers:
//                                 .disabled(focusVM.phase != .idle)  // FIXME: does this block editing while running?
//                                 .submitLabel(.done)
//                                 .validatingState(state: vState, palette: p)    // FIXME: if shouldShowValidation instead?
//                                 */
////                                    .toolbar {
////                                        ToolbarItemGroup(placement: .keyboard) {
////                                            Spacer()
////                                            Button("Done") {
////                                                intentionFocused = false
////                                            }
////                                        }
////                                    }
//                                // if shouldShowValidation {
//                                //  ValidationCaption(state: .invalid(messages: focusVM.tileText.taskValidationMessages), palette: p)
//                                // }
//                            }
//
//                        TextField("", text: $focusVM.tileText, prompt: T("Add intention", .caption))
//                                .focused($intentionFocused)
//                                .submitLabel(.done)
//                                .validatingField(state: vState, palette: p)
//                                .disabled(!isInputActive)
//                                .autocorrectionDisabled()
//                                .textInputAutocapitalization(.sentences)
//
//                                // only shows the “empty/spaces” error when the user actually taps Done with blank input
//                                .onSubmit {
//                                    let trimmed = focusVM.tileText.trimmingCharacters(in: .whitespacesAndNewlines)
//                                    guard !trimmed.isEmpty else { showEmptySubmitError = true; return }
//                                    showEmptySubmitError = false
//                                    Task { try? await focusVM
//                                        .addTileAndPrepareForSession(trimmed) }
//                                    }
//
//                            if shouldShowValidation {
//                                ValidationCaption(
//                                    state: .invalid( messages: focusVM.tileText .taskValidationMessages),
//                                    palette: p
//                                )
//                            }

//                            // Guidance + Messages (no Add/Begin here)
//                            DynamicMessageAndActionArea(
//                                focusVM: focusVM,
//                                onRecalibrateNow: { focusVM.showRecalibrate = true }
//                            )
//                            .environmentObject(theme)

//                            // Centered countdown
//                            if focusVM.phase == .running {
//                                DynamicCountdown(
//                                    fVM: focusVM,
//                                    palette: p,
//                                    progress: Double(focusVM.countdownRemaining) / Double( TimerConfig.current.chunkDuration )
//                                )
//                                .frame(maxWidth: .infinity)  // centers fixed-size content
//                            }
//                    }
//                    .padding(.top, 8)
//                    // Drop focus when we start running or when we leave the screen
//                    .onChange(of: focusVM.phase) { phase in
//                        if phase == .running { intentionFocused = false }
//                    }
//                    .onDisappear { intentionFocused = false }
//                    .background(p.background.ignoresSafeArea())
//                    //                    .ignoresSafeArea(.keyboard, edges: .bottom)         //FIXME: Remove this if keyboard gets weird lifting content
//                    .disabled(focusVM.phase != .idle)  //FIXME: Remove this if keyboard toolbar becomes inert // Text field inactive once running
//                }

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
//                .fullScreenCover(isPresented: $focusVM.showRecalibrate) {
//                    RecalibrationV(vm: recalibrationVM)
//                }

// Bottom inset: slots + single CTA
//                .safeAreaInset(edge: .bottom, spacing: 10) { BottomComposer }
//                //  .safeAreaInset(edge: .bottom) {  if !focusVM.showRecalibrate { BottomComposer }}
//
//                .overlay(alignment: .bottom) {
//                    BottomComposer
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//                        .padding(.bottom, 16)        // adjust here to clear the tab bar
//                        .background(.thinMaterial)
//                        .ignoresSafeArea(edges: .bottom)
//                }
//            }
////        }
//        .onReceive(
//            NotificationCenter.default.publisher(
//                for: .init("dev.openRecalibration")
//            )
//        ) { _ in
//            focusVM.showRecalibrate = true
//        }
//    }

//    // MARK: Bottom composer
//    @ViewBuilder
//    private var BottomComposer: some View {
//        let completedSlotIndex: Int? =
//            (focusVM.currentSessionChunk >= 1) ? 1 : nil  // slots = [second, first]
//        VStack {
//            // two rows, bottom fills first
//            ForEach(0..<slots.count, id: \.self) { idx in
//                let txt = slots[idx]
//                let filled = (txt?.isEmpty == false)
//                let tileIsCompleted = (completedSlotIndex == idx)
//                let slotBg =
//                    filled ? p.accent.opacity(0.9) : p.accent.opacity(0.35)
//
////                ZStack {
//                    // card
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                        .fill(slotBg)
//                        .overlay(
//                            RoundedRectangle(
//                                cornerRadius: 1,
//                                style: .continuous
//                            )
////                            .debugBackground(.green)
//                            .stroke(p.border, lineWidth: 10)
//                        )
//                        .frame(height: 50)
//                        .contentShape(
//                            RoundedRectangle(
//                                cornerRadius: 1,
//                                style: .continuous
//                            )
//
//                        )
////                        .debugBackground(.green)
//                    // Handles color and checkmark icon within the tiles
//                        .overlay {
//                            if diffNoColor && !filled {
//                                RoundedRectangle(
//                                    cornerRadius: 10,
//                                    style: .continuous
//                                )
//
//                                .stroke(
//                                    style: StrokeStyle(lineWidth: 10, dash: [5])
//                                )
//                                .foregroundStyle(p.border)
//                            }
//                        }
//
//
//                    // Tile 2, Tile 2 text
//                    if let text = txt, !text.isEmpty {
//                        HStack{
//                            Text(text)
//                                .lineLimit(1)
//                                .minimumScaleFactor(0.9)
//                                .foregroundStyle(
//                                    tileIsCompleted
//                                        ? p.text.opacity(0.55) : p.text
//                                )
//
//                            if tileIsCompleted {
//                                Image(systemName: "checkmark.circle")
//                                    .foregroundStyle(p.accent)
//                                    .accessibilityHidden(true)
//                            }
//                        }
//                        .padding(.horizontal, 8)
//                        .frame(alignment: .leading)
//
//
//                    } else {
//                        Image(systemName: "plus")
//                            .font(.headline)
//                            .foregroundStyle(p.accent.opacity(0.6))
//                            .accessibilityHidden(true)
//                    }
////                }
////                .opacity(tileIsCompleted ? 0.7 : 1.0)
////                .accessibilityElement(children: .combine)
////                .accessibilityLabel(
////                    filled
////                        ? (tileIsCompleted
////                            ? "Intention completed" : "Intention")
////                        : "Empty slot"
////                )
////                .accessibilityHint(
////                    filled ? "" : "Add an intention above, then press Add."
////                )
//            }
//
//            Button {
//                Task { await focusVM.handlePrimaryTap() }
//            } label: {
//                T(ctaTitle, .section).monospacedDigit()
//            }
//            .primaryActionStyle(screen: screen)
//            .accessibilityIdentifier("primaryCTA")
//        }
//        /// tile and begin/add container controls
//        .padding(.horizontal, 10)
//        .padding(.bottom, 10)
//        .background(.thinMaterial)
//        .cornerRadius(10)
//        .animation(.easeInOut(duration: 0.2), value: focusVM.tiles)
//    }

//     KEEP "vm" so type checker isn't tripped up as it might be with 'focusVM' naming
//    @ViewBuilder
//    private func tileCell(for slot: Int) -> some View {
//        if let t = tile(at: slot) {  // FIXME: rename t to cellContents
//            let vm = focusVM
//            TileCell(tile: t)
//                .opacity(vm.thisTileIsCompleted(t) ? 0.55 : 1.0)
//                .overlay(alignment: .topLeading) {
//                    if vm.thisTileIsCompleted(t) {
//                        Image(systemName: "checkmark.circle")
//                            .symbolRenderingMode(.palette)
//                            .foregroundStyle(.green)
//                            .imageScale(.large)
//                            .padding(6)
//                    }
//                }
//        } else {
//            EmptyView()
//        }
//    }
//
//    private var ctaTitle: String {
//        if focusVM.tiles.count < 2 { return "Add" }
//        if focusVM.phase == .idle { return "Begin" }
//        if focusVM.phase == .finished && focusVM.currentSessionChunk == 1 {
//            return "Next"
//        }
//        return "Begin"
//    }
//
//    private var slots: [String?] {
//        let first =
//            focusVM.tiles.indices.contains(1) ? focusVM.tiles[0].text : nil
//        let second =
//            focusVM.tiles.indices.contains(2) ? focusVM.tiles[1].text : nil
//        return [first, second]
//    }
//
//    private func tile(at slot: Int) -> TileM? {
//        let tileInto = focusVM.tiles
//        guard (0..<tileInto.count).contains(slot) else { return nil }
//        return tileInto[slot]
//    }
//}
//// Hydrate the VM: tiles, phase, chunk index, and remaining time

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
