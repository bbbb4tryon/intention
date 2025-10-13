//
//  FocusSessionVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
import Foundation

/// FocusSessionVM talks to ContinuousClockActor and drives the UI
/// Errors: make UI-called methods async throws (no wrapper)
@MainActor
final class FocusSessionVM: ObservableObject {
    
    /// UI state of the current 20-min chunk
    enum Phase: String, Codable, Sendable { case none, idle, running, finished, paused }
    
    //    private struct BackgroundSnapshot: Codable, Equatable {
    //        var tookAt: TimeInterval        // Date().timeIntervalSince1970
    //        var remainingSeconds: Int
    //        var phaseWasRunning: Bool
    //        var chunkIndex: Int
    //    }
    //
    //    @AppStorage("focus.lastSnapshot") private var lastSnapshotData: Data = Data()
    //
    //    private func saveSnapshot(remaining: Int, running: Bool, chunk: Int) {
    //        let snap = BackgroundSnapshot(
    //            tookAt: Date().timeIntervalSince1970,
    //            remainingSeconds: remaining,
    //            phaseWasRunning: running,
    //            chunkIndex: chunk
    //        )
    //        if let data = try? JSONEncoder().encode(snap) {
    //            lastSnapshotData = data
    //        }
    //    }
    //
    //    private func loadSnapshot() -> BackgroundSnapshot? {
    //        guard !lastSnapshotData.isEmpty,
    //              let snap = try? JSONDecoder().decode(BackgroundSnapshot.self, from: lastSnapshotData)
    //        else { return nil }
    //        return snap
    //    }
    //
    //    private func clearSnapshot() { lastSnapshotData = Data() }
    //
    // MARK: - Published UI State
    @Published var tileText: String = ""
    {
        didSet { validationMessages = tileText.taskValidationMessages } /// Input field for tiles' text;   Validate whenever tileText changes
    }
    @Published var tiles: [TileM] = []              /// List of current session tiles (max 2)
    @Published var canAdd: Bool = true              /// Flag if user can add more tiles at that point
    @Published var sessionActive: Bool = false      /// Overall session state (two 20-min chunks)
    @Published var showRecalibrate: Bool = false    /// Whether to show recalibration
    @Published var countdownRemaining: Int          /// Secs remaining in 20 minutes for individual tile task - set via config
    @Published var phase: Phase = .none             /// State of the *current* 20-min countdown chunk
    @Published var currentSessionChunk: Int = 0     /// Index of current chunk (0 or 1): Tracks which 20-min chunk of the session is active
    @Published var sessionHistory: [[TileM]] = []   /// Array of tiles completed in this session of 2 chunks
    @Published var lastError: Error?                /// Used to trigger the UI visual error overlay
    @Published var validationMessages: [String] = []
    @Published private(set) var didHapticForChunk: Set<Int> = []    /// remembers which chunk indices have already buzzed
    /// ^ returning from background for re-entering a completion can't "double buzz"
    
    weak var historyVM: HistoryVM?                      /// Link to history view model for/to save completed sessions
    ///
    // MARK: Dependencies
    //    private static let activeSnapshotKey = "focus.activeSession"
    private let haptics: HapticsClient
    private let config: TimerConfig
    private let persistence: any Persistence            /// handles activeSessionSnapshot via Persistence
    private let timeActor: ContinuousClockActor
    private var chunkCountdown: Task<Void, Never>?        /// background live time keeper/ticker
    private var sessionCompletionTask: Task<Void, Never>? /// background timer for the entire session (2x 20-min chunks)
    private var runningDeadline: Date?                  /// property to mark a deadline when a chunk starts or resumes
    
    var chunkDuration: Int { config.chunkDuration }     /// Default 20 min chunk duration constant
    
    // MARK: - Cancel or teardown
    deinit {
        chunkCountdown?.cancel()
        sessionCompletionTask?.cancel()
    }
    
    // MARK: Snapshot (the VM snapshot is canonical)
    private struct VMSnapshot: Codable, Equatable {
        var tileTexts: [String]
        var phase: Phase
        var chunkIndex: Int
        var deadline: Date?
        var remainingSeconds: Int       // fallback when no deadline
        var showRecalibrate: Bool
        var didHapticForChunk: [Int]
    }
    private let vmSnapshotKey = "focus.vm.snapshot.v2"
    
    // MARK: Init
    init(
        previewMode: Bool = false,
        haptics: HapticsClient,
        config: TimerConfig = .current,
        persistence: any Persistence = PersistenceActor()
    ){
        self.haptics = haptics
        self.config = config
        self.persistence = persistence
        self.countdownRemaining = config.chunkDuration
        self.timeActor = ContinuousClockActor(config: config)
        
        if previewMode {
            tiles = [TileM(text: "Tile 1"), TileM(text: "Tile 2")]
            tileText = "Start another..."
            canAdd = false
            sessionActive = true
            currentSessionChunk = 1
            phase = .running
            countdownRemaining = config.chunkDuration / 20
        }
    }
    
    // MARK: Derived
    private var hasTwoTiles: Bool { tiles.count == 2 }
    /// Guard for phases -> canPrimary for flipping to the "Add" button
    private var inputIsValid: Bool {
        let t = tileText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && t.taskValidationMessages.isEmpty
    }
    
    var canPrimary: Bool {
        // Only allow "Add" when the current input is valid AND you’re not running
        if !hasTwoTiles { return inputIsValid && phase != .running }
        // Only allow "Begin" when not running (fresh or between chunks)
        else { return phase == .idle || phase == .none || (phase == .finished && currentSessionChunk == 1)
        }
    }
    
    /// Tap handler here, the button widget lives in the Focus view -> Lets the View bind `.disabled(!viewModel.canPrimary)`
    var primaryCTATile: String {
        if !hasTwoTiles { return "Add" }
        if phase == .finished && currentSessionChunk == 1 { return "Next" }
        return "Begin"
    }
    
    /// Enter idle early and consistently; cases never returns an empty label
    func enterIdleIfNeeded() {
        if phase == .none { phase = .idle }
    }
    
    // MARK: Control public funnel used by TextField and CTA
    enum PrimaryCTAResult { case added, began }
    
    /// The one funnel both TextField.onSubmit and the bottom CTA should use.
    @discardableResult
    func handlePrimaryTap(validatedInput: String?) async throws -> PrimaryCTAResult {
        if !hasTwoTiles {
            // the ADDED path
            let text = (validatedInput ?? tileText).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.taskValidationMessages.isEmpty else {
                throw FocusSessionError.emptyInput
            }
            try await addTileAndPrepareForSession(text)
            return .added
        } else {
            // the BEGIN / NEXT path
            guard phase == .idle || phase == .none || (phase == .finished && currentSessionChunk == 1) else {
                throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
            }
            try await beginOverallSession()
            return .began
        }
    }
    
    // MARK: - Tile Handling
    func addTileAndPrepareForSession(_ text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {   throw FocusSessionError.emptyInput    }
        guard tiles.count < 2 else {    throw FocusSessionError.tooManyTiles()    }
        
        let newTile = TileM(text: trimmed)
        /// Cross-actor hop; no 'try' because the actor method doesn't throw
        let accepted = await timeActor.addTile(newTile)
        guard accepted else { throw FocusSessionError.tooManyTiles(limit: 2) }
        
        tiles.append(newTile)
        tileText = ""
        canAdd = tiles.count < 2       /// Keeps flag in sync
        // Wrap noisy debug prints in if debug
        haptics.added()
        saveVMSnapshot()
    }
    
    // MARK: Start a 20-min chunk
    private func startCurrent20MinCountdown(seconds: Int? = nil) async {
        //        guard hasTwoTiles, phase != .running else {
        //            throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
        //        }
        phase = .running
        sessionActive = true
        // cancels any existing timers
        //        stopCurrent20MinCountdown()
        //        phase = .running
        
        let total = seconds ?? config.chunkDuration
        countdownRemaining = total
        // ContinuousClock avoids wall-clock jumps from time/date changes
        //        runningDeadline = Date().addingTimeInterval(TimeInterval(seconds)) // seconds = chunkDuration
        saveVMSnapshot()
        
        //        let clock = ContinuousClock()
        //        let deadline = clock.now.advanced(by: .seconds(seconds))
        //        chunkCountdown = Task { [weak self] in
        //            guard let self else { return }
        //            while !Task.isCancelled {
        //                let remaining = max(0, Int(clock.now.duration(to: deadline).components.seconds))
        //                await MainActor.run { self.countdownRemaining = remaining }
        //                // FIXME: print once per minute for debug purposes
        //                if remaining % 60 == 0 {
        //                    debugPrint("[FocusSessionVM.startCurrent20MinCountdown] tick remaining=\(remaining)")
        //                }
        //                if remaining == 0 { break }
        //                try? await clock.sleep(for: .seconds(1))
        //            }
        //
        //            /// >>> All post-finish work happens INSIDE the Task <<<
        //            await MainActor.run {
        //                guard self.phase == .running else { return }
        //                self.fireDoneHapticOnce()
        //                // >>> Single place that advances and decides
        //                self.finishCurrentChunk()
        //                self.saveSnapshot()
        //            }
        //            //        await MainActor.run { self.naturallyAdvanceSessionChunk() }
        //            // Clear the task
        //            await MainActor.run { self.chunkCountdown = nil }
        //        }
        
        await timeActor.startTicking(
            totalSeconds: total,
            onTick: { [ weak self ] secs in
                Task { @MainActor in self?.countdownRemaining = secs }
            },
            onFinish: { [ weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.countdownRemaining = 0
                    if self.phase == .running {
                        self.fireDoneHapticOnce()
                        self.finishCurrentChunk()
                    }
                }
            }
        )
    }
    
    // MARK: Begin overall session (two chunks)
    func beginOverallSession() async throws {
        //        guard hasTwoTiles, (phase == .idle || phase == .none || (phase == .finished && currentSessionChunk == 1)) else {
        //            throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
        //        }
        guard hasTwoTiles else {
            throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
        }
        await timeActor.startSessionTracking()
        if phase == .finished && currentSessionChunk == 1 {
            // start next chunk, explicitly //FIXME: should ask Next, per DynamicMessageAndAction
            await startCurrent20MinCountdown()
        } else {
            await startCurrent20MinCountdown()
        }
        //        sessionActive = true
        //        try startCurrent20MinCountdown()
    }
    
    // MARK: User pause / resume
    func pauseCurrent20MinCountdown() async {
        guard phase == .running else { return }
        await timeActor.pauseTicking(currentRemaining: countdownRemaining)
        phase = .paused
        saveVMSnapshot()
    }
    
    func resumeCurrent20MinCountdown() async throws {
        guard phase == .paused else { throw FocusSessionError.unexpected }
        await timeActor.resumeTicking(
            onTick: { [weak self] secs in
                Task { @MainActor in self?.countdownRemaining = secs }
            },
            onFinish: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.countdownRemaining = 0
                    if self.phase == .running {
                        self.fireDoneHapticOnce()
                        self.finishCurrentChunk()
                    }
                }
            }
        )
        phase = .running
        saveVMSnapshot()
        
        //        chunkCountdown?.cancel()
        //        chunkCountdown = nil
        //        phase = .paused
        // paused == wall clock setup
        //        runningDeadline = nil
        //        saveSnapshot()
        //
        //        let seconds = countdownRemaining
        //        guard seconds > 0 else {
        //            // Nothing to resume; treat as finished-same finisher as startCurrent...()
        //            finishCurrentChunk()
        //            return
        //        }
        //        phase = .running
        //        saveSnapshot()
        //
        //        let clock = ContinuousClock()
        //        let deadline = clock.now.advanced(by: .seconds(seconds))
        //        chunkCountdown = Task { [weak self] in
        //            guard let self else { return }
        //            while !Task.isCancelled {
        //                let remaining = max(0, Int(clock.now.duration(to: deadline).components.seconds))
        //                await MainActor.run { self.countdownRemaining = remaining }
        //                if remaining == 0 { break }
        //                try? await clock.sleep(for: .seconds(1))
        //            }
        //            await MainActor.run {
        //                guard self.phase == .running else { return }
        //                self.phase = .finished
        //                self.fireDoneHapticOnce()
        //                // >>> Single place that advances and decides
        //                self.finishCurrentChunk()
        //                self.chunkCountdown = nil
        //            }
        //        }
    }
    
    // MARK: App lifecycle (RootView calls these)
    func suspendTickingForBackground() async {
        // 1) Save *VM* snapshot (canonical UI/session)
        saveVMSnapshot()
        // 2) Let actor stop work but keep endInstant so wall-time continues
        await timeActor.suspendForBackground()
        // 3) (Optional) write actor safety snapshot to disk for kill-restore
        if let snap = await timeActor.makeSnapshot() {
            try? await persistence.write(snap, to: "focus.actor.safety")
        }
    }
    
    func resumeTickingAfterForeground() async {
        // First, try the actor’s monotonic recompute
        if let remaining = await timeActor.remainingAfterForeground() {
            if remaining <= 0 {
                // Finished while away
                phase = .finished
                countdownRemaining = 0
                finishCurrentChunk()
                clearVMSnapshot()
                return
            }
            // Re-arm ticking
            await startCurrent20MinCountdown(seconds: remaining)
            return
        }
        
        // If actor had no state (process kill), try safety snapshot (aux) THEN VM snapshot (canonical)
        if let safety: ContinuousClockActor.Snapshot =
            try? await persistence.readIfExists(ContinuousClockActor.Snapshot.self, from: "focus.actor.safety") {
            
            // Restore into actor and VM scaffolding
            await timeActor.restoreFromSafetySnapshot(safety)
            await startCurrent20MinCountdown(seconds: safety.remainingSeconds)
            try? await persistence.clear("focus.actor.safety")
            return
        }
        
        // Finally, VM snapshot as canonical (e.g., after kill/launch)
        if let vmSnap: VMSnapshot = try? await persistence.readIfExists(VMSnapshot.self, from: vmSnapshotKey) {
            applyVMSnapshot(vmSnap)
            clearVMSnapshot()
            if phase == .running {
                // Recreate ticking respecting paused/running
                if phase == .running {
                    await startCurrent20MinCountdown(seconds: vmSnap.remainingSeconds)
                }
            }
            
            //        guard let snap = loadSnapshot() else { return }
            //
            //        // Wall-clock delta
            //        let elapsed = max(0, Int(Date().timeIntervalSince1970 - snap.tookAt))
            //
            //        // Only subtract time if we were running when we left
            //        let recomputedRemaining = snap.phaseWasRunning
            //        ? max(0, snap.remainingSeconds - elapsed)
            //        : snap.remainingSeconds
            //
            //        // If time ran out while away, finish cleanly; otherwise resume exactly
            //        if recomputedRemaining <= 0 {
            //            remainingSeconds = 0
            //            phase = .finished
            //            isActive = false
            //            clearSnapshot()
            //            await handleChunkFinished()  // your existing completion path
            //            return
            //        }
            //
            //        // Safe resume
            //        currentSessionChunk = snap.chunkIndex
            //        remainingSeconds = recomputedRemaining
            //        phase = snap.phaseWasRunning ? .running : .paused
            //        isActive = true
            //
            //        clearSnapshot()
            //
            //        if snap.phaseWasRunning {
            //            await timer.start(tickEvery: 1) { [weak self] in
            //                await self?.onTick()
            //            }
            //        }
        }
    }
    
    func restoreActiveSessionIfAny() async {
        // On cold launch; reuse the same logic as foreground
        await resumeTickingAfterForeground()
    }

    // MARK: End-of-chunk/session
    /// ONLY advancement path; Marks the current chunk complete, advances chunk index once,
    ///     performs end-of-session work when both chunks are done.
    ///     NO NEED for a separate `mark()` or `check()` needed
    func finishCurrentChunk() {
        currentSessionChunk += 1
        if currentSessionChunk >= 2 {
            sessionActive = false
            phase = .finished
            showRecalibrate = true

            if let targetCategoryID = historyVM?.generalCategoryID {
                for tile in tiles.prefix(2) {
                    historyVM?.addToHistory(tile, to: targetCategoryID)
                }
            }
        } else {
            phase = .finished   // between chunks; UI will show Next
        }
        // Clear the running deadline; take a snapshot of the new state
        runningDeadline = nil
        saveVMSnapshot()
    }

    /// Resets the session state for a new start - non-throwing; async because we `await` the actor
    func resetSessionStateForNewStart() async {
//        stopCurrent20MinCountdown()                     /// Ensures any running countdown is stopped
        tiles = []
        tileText = ""
        canAdd = true
        sessionActive = false
        showRecalibrate = false
        //        completedTileIDs.removeAll()
        currentSessionChunk = 0
        phase = .none
        countdownRemaining = config.chunkDuration
        didHapticForChunk.removeAll()
        await timeActor.resetSessionTracking()
        clearVMSnapshot()
//        debugPrint("[FocusVM.resetSessionStateForNewStart] state NOT reset for a new session.")
    }
    
    /// checkmarks + Calls when each 20-min chunk completes:
    /// you persist currentSessionChunk. On restore, new TileM ids are created, so any stored completedTileIDs wouldn’t match; index-derived stays correct.
    func thisTileIsCompleted(_ tile: TileM) -> Bool {
        guard let idx = tiles.firstIndex(where: { $0.id == tile.id }) else { return false }
        //        completedTileIDs.contains(tile.id)
        return idx < currentSessionChunk
    }
//    
//    /// Stops and resets the current countdown timer
//    func stopCurrent20MinCountdown() {
//        chunkCountdown?.cancel()
//        chunkCountdown = nil
//        phase = .idle
//        countdownRemaining = chunkDuration
//        debugPrint("Current 20-min countdown stopped and reset")
//    }
    
//    /// Adds a tile or starts session, depending on context
//    func beginSessionFlow() async throws {
//        if tiles.count < 2 {
//            try await addTileAndPrepareForSession(tileText)
//        } else {
//            // NOTE: -
//            /*
//             If two tiles are already present, and a countdown just finished,
//             this button could be used to explicitly start the *next* 20-min chunk
//             if the user chose not to immediately continue.
//             For now, based on your description, this button mainly triggers `addTileAndPrepareForSession`.
//             // We might need more explicit UI for "Start next 20-min chunk".
//             */
//            print("All tiles added. Consider adding logic for starting next chunk explicitly.")
//            try await beginOverallSession()
//        }
//    }
//
//    
    //
    //    /// (Part 2) checkmarks + Calls when each 20-min chunk completes:
    //    func markCurrentTileCompleted() {
    //        guard currentSessionChunk < tiles.count else { return }
    //        completedTileIDs.insert(tiles[currentSessionChunk].id)
    //        currentSessionChunk += 1
    //    }
    //    /// Chunks session for completion, triggers recalibration **uses HistoryVM canonical IDs** Flow Control
    //    private func checkSessionCompletion() {
    //        if currentSessionChunk >= 2 {                               /// both chunks done
    //            sessionActive = false                                   /// 40-min overall session done
    //            markCurrentTileCompleted()
    //            showRecalibrate = true                                  /// modal triggered
    //            debugPrint("Recalibration choice modal should display")
    //            /// Bounded tile history call, add tiles to category
    //            guard let targetCategoryID = historyVM?.generalCategoryID else {
    //                debugPrint("[FocusSessionVM.checkSessionCompletion] missing historyVM.generalCategoryID"); return
    //            }
    //            for tile in tiles.prefix(2) {
    //                historyVM?.addToHistory(tile, to: targetCategoryID)
    //            }
    //            /// NOTE: - Don't reset actor for new session here - user will on modal
    //        } else {
    //            print("""
    //                  Completed the \(currentSessionChunk)!
    //                  Well done!
    //                  On to the next one
    //                  """)
    //            /// If currentSessionChunk is 1 and phase==finished, the UI will show "Start Next 20 Minutes"
    //        }
    //    }
    
    // MARK: Haptics (guard once per chunk)
    // Pattern to call haptic once per completion
    private func fireDoneHapticOnce() {
        guard !didHapticForChunk.contains(currentSessionChunk) else { return }
        didHapticForChunk.insert(currentSessionChunk)
        haptics.notifyDone()            // don't call itself with fireDoneHapticOnce()
    }
    
    // MARK: VM snapshot helpers (canonical)
    private func makeVMSnapshot() -> VMSnapshot {
        VMSnapshot(tileTexts: tiles.map(\.text),
                   phase: phase,
                   chunkIndex: currentSessionChunk,
                   deadline: nil,                       // deadline-based restore
                   remainingSeconds: countdownRemaining,   // always stores a fallback
                   showRecalibrate: showRecalibrate,
                   didHapticForChunk: Array(didHapticForChunk)
        )
    }
    
    private func saveVMSnapshot() {
        let snap = makeVMSnapshot()
        Task { try? await persistence.write(snap, to: vmSnapshotKey) }
    }
    
    private func clearVMSnapshot() {
        Task { await persistence.clear(vmSnapshotKey)}
    }
    
    private func applyVMSnapshot(_ s: VMSnapshot) {
        tiles = s.tileTexts.map { TileM(text: $0) }
        phase = s.phase
        currentSessionChunk = s.chunkIndex
        showRecalibrate = s.showRecalibrate
        didHapticForChunk = Set(s.didHapticForChunk)
        sessionActive = (phase == .running || phase == .paused || currentSessionChunk > 0)
    }
    
    // MARK: Utilities
    var formattedTime: String {
        let minutes = countdownRemaining / 60
        let seconds = countdownRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Sets flag to trigger recalibration modal
    func checkRecalibrationNeeded() {
        if tiles.count == 2 {
            showRecalibrate = true
        }
    }
    
    //  NOTE: Do not set as a global function - needs to modify `lastError`
    func performAsyncAction(_ action: @escaping () async throws -> Void) {
        Task {
            do { try await action() }
            catch {
                debugPrint("[FocusSessionVM.performAsyncAction] error:", error)
                self.lastError = error
            }
        }
    }
    
    //    /// Button should be enabled when: <2 tiles and trimmed input is non-empty and not running,or exactly 2 tiles and phase is .idle.
    //    var canPrimary: Bool {
    //        if tiles.count < 2 {
    //            let trimmed = tileText.trimmingCharacters(in: .whitespacesAndNewlines)
    //            return !trimmed.isEmpty && tileText.taskValidationMessages.isEmpty
    //        } else {
    //            return phase == .idle
    //        }
    //    }
    
    // MARK: VM snapshot helpers (canonical)
//    private func makeSnapshot() -> ActiveSessionSnapshot {      //FIXME: rename to makeActiveSnapshot()
//        let deadlineAtResume = runningDeadline ?? Date().addingTimeInterval(TimeInterval(max(0, countdownRemaining)))
//        return ActiveSessionSnapshot(
//            tileTexts: tiles.map(\.text),
//            phase: phase,
//            chunkIndex: currentSessionChunk,
//            deadline: deadlineAtResume
//        )
//    }
//    
//    private func saveSnapshot() {
//        Task { try? await persistence.write(makeSnapshot(), to: Self.activeSnapshotKey) }
//    }
//    
//    private func clearSnapshot() {
//        Task { await persistence.clear(Self.activeSnapshotKey) }
//    }
    
//    // treat a snapshot as stale if its deadline is older than one chunk duration before now.
//    //      for any 20 min chunk, deadline < now - 20m is obviously stale
//    func restoreActiveSessionIfAny() async {
//        guard let snapshot: ActiveSessionSnapshot =
//                try? await persistence.readIfExists(ActiveSessionSnapshot.self, from: Self.activeSnapshotKey)
//        else { return }
//        
//        // Stale if the deadline is more than one full chunk ago
//        if snapshot.deadline < Date().addingTimeInterval(-TimeInterval(config.chunkDuration)){
//            await persistence.clear(Self.activeSnapshotKey)
//            return
//        }
//        
//        // 3) computedRemaining based on deadline, if present; else fall back to legacy fields
//        let remainingAfterDeadline = max(0, Int(snapshot.deadline.timeIntervalSinceNow))
//        
//        // Mutate UI state on main; decide whether we should resume afterwards
//        let shouldResume: Bool = await MainActor.run {
//            tiles                 = snapshot.tileTexts.map { TileM(text: $0) }
//            currentSessionChunk     = snapshot.chunkIndex
//            countdownRemaining      = min(remainingAfterDeadline, config.chunkDuration)
//            
//            if snapshot.phase == FocusSessionVM.Phase.running && countdownRemaining > 0 {
//                // 1) don't use .paused
//                phase          = .running
//                runningDeadline = snapshot.deadline
//                // Recreate the 1 Hz VM ticker via the ContinuousClock path:
//                // 2) will set a fresh runningDeadline again; safe
//                chunkCountdown?.cancel()
//                return true
//            } else if snapshot.phase == .running && countdownRemaining == 0 {
//                // 3) time actually expired while away - finish at once
//                phase = .finished
//                finishCurrentChunk()
//                return false
//            } else {
//                // 4) according to whatever has occurred - idle, paused, finished - restore to that point
//                phase = snapshot.phase
//                return false
//            }
//        }
//        if shouldResume {
//            // This is async; call it *outside* MainActor.run’s synchronous closure
//            try? await resumeCurrent20MinCountdown()
//        }
//        await MainActor.run { sessionActive = (phase == .paused || phase == .running || currentSessionChunk > 0) }
//    }

}

extension FocusSessionVM {
    var inputValidationState: ValidationState {
        let msgs = tileText.taskValidationMessages
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    func debugPhaseSummary(_ tag: String = "") -> String {
        "[VM] \(tag) tiles=\(tiles.count) phase=\(phase) remaining=\(countdownRemaining) active=\(sessionActive)"
    }
    
}

/// Error cases for focus session flow
enum FocusSessionError: Error, Equatable, LocalizedError {
    case emptyInput
    case tooManyTiles(limit: Int = 2)
    case invalidBegin(phase: FocusSessionVM.Phase, tilesCount: Int)
    case persistenceFailed
    case unexpected
    
    var errorDescription: String? {
        switch self {
        case .emptyInput: return "Please enter a task, what you intend to do."
        case .tooManyTiles(let limit): return "You can only add \(limit) intentions."
        case .invalidBegin(_, let count): return "Can't begin with \(count) tiles."
        case .persistenceFailed: return "Saving failed. Try again."
        case .unexpected: return "Something went wrong. Please try again."
        }
    }
    
}
