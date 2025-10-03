//
//  FocusSessionVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
import Foundation

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

/// FocusSessionVM talks to FocusTimerActor and drives the UI
/// Errors: make UI-called methods async throws (no wrapper)
@MainActor
final class FocusSessionVM: ObservableObject {
    
    /// UI state of the current 20-min chunk
    enum Phase: String, Codable, Sendable {
        case none, idle, running, finished, paused
    }
    
    // MARK: - Published UI State
    @Published var tileText: String = "" { didSet { validationMessages = tileText.taskValidationMessages }}         /// Input field for tiles' text;   Validate whenever tileText changes
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
    
    @Published private(set) var completedTileIDs: Set<UUID> = []
    
    // MARK: - Internal Properties
    private static let activeSnapshotKey = "focus.activeSession"
    private let haptics: HapticsClient
    private let config: TimerConfig
    private let persistence: any Persistence            /// handles activeSessionSnapshot via Persistence
    private let tileAppendTrigger: FocusTimerActor
    private var chunkCountdown: Task<Void, Never>?        /// background live time keeper/ticker
    private var sessionCompletionTask: Task<Void, Never>? /// background timer for the entire session (2x 20-min chunks)
    weak var historyVM: HistoryVM?                      /// Link to history view model for/to save completed sessions
    var chunkDuration: Int { config.chunkDuration }     /// Default 20 min chunk duration constant
    
    // MARK: - Cancel or teardown
    deinit {
        chunkCountdown?.cancel()
        sessionCompletionTask?.cancel()
    }
    
    // Preview-friendly Initializer of session state
    init(previewMode: Bool = false, haptics: HapticsClient, config: TimerConfig = .current, persistence: any Persistence = PersistenceActor()) {
        self.haptics = haptics
        self.config = config
        self.persistence = persistence
        self.countdownRemaining = config.chunkDuration
        self.tileAppendTrigger = FocusTimerActor(config: config)
        
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
    
    // MARK: - Tile Submission Logic
    
    /// Adds a new tile to the session if under limit
    func addTileAndPrepareForSession(_ text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {   throw FocusSessionError.emptyInput    }
        guard tiles.count < 2 else {    throw FocusSessionError.tooManyTiles()    }
        
        let newTile = TileM(text: trimmed)
        
        /// Cross-actor hop; no 'try' because the actor method doesn't throw
        let accepted = await tileAppendTrigger.addTile(newTile)
        guard accepted else { debugPrint("[FocusSessionVM.addTileAndPrepareForSession] did not occur"); throw FocusSessionError.tooManyTiles(limit: 2)
        }
        
        tiles.append(newTile)
        tileText = ""
        canAdd = tiles.count < 2       /// Keeps flag in sync
        // Wrap noisy debug prints in if debug
        haptics.added()
    }
    
    /// Starts the 20-min countdown for the current focus session.
    func startCurrent20MinCountdown() throws {
        guard tiles.count == 2, phase != .running else {
            throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
        }
        stopCurrent20MinCountdown()         /// cancels any existing timers
        
        // ContinuousClock avoids wall-clock jumps from time/date changes
        phase = .running
        saveSnapshot()
        let seconds = chunkDuration
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(seconds))
        
        //        countdownRemaining = chunkDuration  /// resets to 20 minutes
        chunkCountdown = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let remaining = max(0, Int(clock.now.duration(to: deadline).components.seconds))
                await MainActor.run { self.countdownRemaining = remaining }
                if remaining == 0 { break }
                try? await clock.sleep(for: .seconds(1))
            }
            //            try? await clock.sleep(for: .seconds(1))
            //            await MainActor.run { self.countdownRemaining -= 1 }
            
            //        guard !Task.isCancelled else { return }     //FIXME: what's this?
            /// >>> All post-finish work happens INSIDE the Task <<<
            await MainActor.run {
                guard self.phase == .running else { return }
                self.phase = .finished
                self.haptics.notifyDone()
                self.naturallyAdvanceSessionChunk()
                self.saveSnapshot()
            }
            //        await MainActor.run { self.naturallyAdvanceSessionChunk() }
            // Clear the task
            await MainActor.run { self.chunkCountdown = nil }
        }
    }
    
    //            if self.countdownRemaining <= 0 && self.phase == .running {
    //                self.phase = .finished
    //                self.haptics.notifyDone()
    //            }
    //        }
    //        self.chunkCountdown = nil
    //        await MainActor.run { self.naturallyAdvanceSessionChunk() }
    //    }
    
    //        chunkCountdown = Task {
    //            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
    //                guard !Task.isCancelled else {  debugPrint("Countdown task cancelled"); return  }
    //                if countdownRemaining > 0 { countdownRemaining -= 1; debugPrint("Session countdown: \(formattedTime)")
    //                } else {    debugPrint("40 min session completed"); break   }
    //            }
    //            
    //            /// Block executes when countdownRemaining reaches 0 or is cancelled
    //            if self.countdownRemaining <= 0 && self.phase == .running {
    //                await MainActor.run {
    //                    self.phase = .finished
    //                    self.haptics.notifyDone()
    //                    debugPrint("`Haptic.notifyDone()` triggered? Current 20-min chunk completed")
    //                }
    //                self.chunkCountdown?.cancel()
    //                self.chunkCountdown = nil
    //                naturallyAdvanceSessionChunk()
    //            }
    
    /// State Mutation - Advances chunk index and checks session completion
    func naturallyAdvanceSessionChunk() {
        currentSessionChunk += 1
        self.checkSessionCompletion()   /// check if chunks session is completed
    }
    
    func pauseCurrent20MinCountdown() async {
        guard phase == .running else { return }
        chunkCountdown?.cancel()
        chunkCountdown = nil
        phase = .paused
        saveSnapshot()
    }
    
    func resumeCurrent20MinCountdown() async throws {
        guard phase == .paused else { throw FocusSessionError.unexpected }
        let seconds = countdownRemaining
        guard seconds > 0 else {
            // Nothing to resume; treat as finished
            phase = .finished
            naturallyAdvanceSessionChunk()
            return
        }
        
        phase = .running
        saveSnapshot()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(seconds))
        
        chunkCountdown = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let remaining = max(0, Int(clock.now.duration(to: deadline).components.seconds))
                await MainActor.run { self.countdownRemaining = remaining }
                if remaining == 0 { break }
                try? await clock.sleep(for: .seconds(1))
            }
            
            await MainActor.run {
                // Only mark finished if we actually were running when the task ended
                guard self.phase == .running else { return }
                self.phase = .finished
                self.haptics.notifyDone()
                self.naturallyAdvanceSessionChunk()
                self.chunkCountdown = nil
            }
        }
    }
    
    /// Stops and resets the current countdown timer
    func stopCurrent20MinCountdown() {
        chunkCountdown?.cancel()
        chunkCountdown = nil
        phase = .idle
        countdownRemaining = chunkDuration
        debugPrint("Current 20-min countdown stopped and reset")
    }
    
    // MARK: - Session Lifecycle/Flow
    
    /// Combined Trigger of Chunks Session (via "Begin")
    func beginOverallSession() async throws {
        /// Use the *current* phase for the error payload
        guard tiles.count == 2, (phase == .idle || phase == .none) else {
            debugPrint("[FocusSessionVM.beginOverallSession] not triggered; no session created."); throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
        }
        await tileAppendTrigger.startSessionTracking()
        sessionActive = true                                /// Overall session activated
        try startCurrent20MinCountdown()                    /// Sets phase = .running inside, First Chunk started
    }
    
    /// Adds a tile or starts session, depending on context
    func beginSessionFlow() async throws {
        if tiles.count < 2 {
            try await addTileAndPrepareForSession(tileText)
        } else {
            // NOTE: -
            /*
             If two tiles are already present, and a countdown just finished,
             this button could be used to explicitly start the *next* 20-min chunk
             if the user chose not to immediately continue.
             For now, based on your description, this button mainly triggers `addTileAndPrepareForSession`.
             // We might need more explicit UI for "Start next 20-min chunk".
             */
            print("All tiles added. Consider adding logic for starting next chunk explicitly.")
            try await beginOverallSession()
        }
    }
    
    /// Resets the session state for a new start - non-throwing; async because we `await` the actor
    func resetSessionStateForNewStart() async {
        stopCurrent20MinCountdown()                     /// Ensures any running countdown is stopped
        tiles = []
        tileText = ""
        canAdd = true
        sessionActive = false
        showRecalibrate = false
        completedTileIDs.removeAll()
        currentSessionChunk = 0
        await tileAppendTrigger.resetSessionTracking()
        clearSnapshot()
        debugPrint("[FocusVM.resetSessionStateForNewStart] state NOT reset for a new session.")
    }
    
    /// Tap handler here, the button widget ilives in the Focus view
    var primaryCTATile: String {
        if tiles.count < 2 { return "Add" }
        switch phase {
        case .idle, .none:  return "Begin"
        case .finished where currentSessionChunk == 1: return "Next"
        default: return "Begin"
        }
    }
    
    /// Let the View bind `.disabled(!viewModel.canPrimary)`
    //FIXME: is this grinding against the Validation version?
    var canPrimary: Bool {
        if tiles.count < 2 {
            let t = tileText.trimmingCharacters(in: .whitespacesAndNewlines)
            return !t.isEmpty && t.taskValidationMessages.isEmpty
        } else {
            return phase == .idle || phase == .none
        }
    }
    /// Control funnel for the button
    enum PrimaryCTAResult { case added, began }
    
    /// Single funnel for both the button and the keyboard's "Done"
    @discardableResult
    func handlePrimaryTap(validatedInput: String?) async throws -> PrimaryCTAResult {
        if tiles.count < 2 {
            // use validatedInput from the View; ball back is own tileText
            let text = validatedInput ?? tileText
            try await addTileAndPrepareForSession(text)
            return .added
        } else if tiles.count == 2 && (phase == .idle || phase == .none) {
            try await beginOverallSession()
            return .began
        } else {
            throw FocusSessionError.invalidBegin(phase: phase, tilesCount: tiles.count)
        }
    }
    
    /// (Part 1) checkmarks + Calls when each 20-min chunk completes:
    func thisTileIsCompleted(_ tile: TileM) -> Bool {
        completedTileIDs.contains(tile.id)
    }
    
    /// (Part 2) checkmarks + Calls when each 20-min chunk completes:
    func markCurrentTileCompleted() {
        guard currentSessionChunk < tiles.count else { return }
        completedTileIDs.insert(tiles[currentSessionChunk].id)
        currentSessionChunk += 1
    }
    /// Chunks session for completion, triggers recalibration **uses HistoryVM canonical IDs** Flow Control
    private func checkSessionCompletion() {
        if currentSessionChunk >= 2 {                               /// both chunks done
            sessionActive = false                                   /// 40-min overall session done
            markCurrentTileCompleted()
            showRecalibrate = true                                  /// modal triggered
            debugPrint("Recalibration choice modal should display")
            /// Bounded tile history call, add tiles to category
            guard let targetCategoryID = historyVM?.generalCategoryID else {
                debugPrint("[FocusSessionVM.checkSessionCompletion] missing historyVM.generalCategoryID"); return
            }
            for tile in tiles.prefix(2) {
                historyVM?.addToHistory(tile, to: targetCategoryID)
            }
            /// NOTE: - Don't reset actor for new session here - user will on modal
        } else {
            print("""
                  Completed the \(currentSessionChunk)!
                  Well done!
                  On to the next one
                  """)
            /// If currentSessionChunk is 1 and phase==finished, the UI will show "Start Next 20 Minutes"
        }
    }
    
    // MARK: - Helpers
    
    /// MM:SS helper to format time
    var formattedTime: String {
        let minutes = countdownRemaining / 60
        let seconds = countdownRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// So cases never returns an empty label
    func enterIdleIfNeeded() {
        if phase == .none { phase = .idle }
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
            do {
                try await action()
            } catch {
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
    
    /// ActiveSessionSnapshot & persistence helpers
    private func makeSnapshot() -> ActiveSessionSnapshot {      //FIXME: rename to makeActiveSnapshot()
        ActiveSessionSnapshot(tileTexts: tiles.map(\.text), phase: phase, chunkIndex: currentSessionChunk, remainingSeconds: countdownRemaining, startedAt: Date())
    }
    
    private func saveSnapshot() {
        Task { try? await persistence.write(makeSnapshot(), to: Self.activeSnapshotKey) }
    }
    
    private func clearSnapshot() {
        Task { await persistence.clear(Self.activeSnapshotKey) }
    }
    
    func restoreActiveSessionIfAny() async {
        guard let snap: ActiveSessionSnapshot =
                try? await persistence.readIfExists(ActiveSessionSnapshot.self, from: Self.activeSnapshotKey)
        else { return }
        
        // discard stale (older than 8h, tune as you like)
        guard Date().timeIntervalSince(snap.startedAt) < 8*60*60 else {
            await persistence.clear(Self.activeSnapshotKey); return
        }
        
        await MainActor.run {
            tiles = snap.tileTexts.map { TileM(text: $0) }
            currentSessionChunk = snap.chunkIndex
            countdownRemaining = min(max(snap.remainingSeconds, 0), config.chunkDuration)
            phase = snap.phase == .running ? .paused : snap.phase   // safe resume point; forces "Paused" when re-entering the app
            sessionActive = (phase == .paused || phase == .running || currentSessionChunk > 0)
        }
    }
}

extension FocusSessionVM {
    var inputValidationState: ValidationState {
        let msgs = tileText.taskValidationMessages
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }
    
//    /// A tile is "completed" iff its index is below the currentSessionChunk (0 or 1).
//    func thisTileIsCompleted(_ tile: TileM) -> Bool {
//        guard let idx = tiles.firstIndex(of: tile) else { return false }
//        //           guard let idx1 = tiles.index(after: idx) else { return false }
//        //           return idx1 < idx < currentSessionChunk
//        return idx < currentSessionChunk
//    }
}
