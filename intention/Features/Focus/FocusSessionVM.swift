//
//  FocusSessionVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
import Foundation

/// Error cases for focus session flow
enum FocusSessionError: Error, Equatable {
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
    enum Phase {
        case notStarted, running, finished
    }

    // MARK: - Published UI State
    @Published var tileText: String = ""  { didSet { validationMessages = tileText.taskValidationMessages }}         /// Input field for tiles' text;   Validate whenever tileText changes
        
    @Published var tiles: [TileM] = []              /// List of current session tiles (max 2)
    @Published var canAdd: Bool = true              /// Flag if user can add more tiles at that point
    @Published var sessionActive: Bool = false      /// Overall session state (two 20-min chunks)
    @Published var showRecalibrate: Bool = false    /// Whether to show recalibration
    @Published var countdownRemaining: Int          /// Secs remaining in 20 minutes for individual tile task - set via config
    @Published var phase: Phase = .notStarted       /// State of the *current* 20-min countdown chunk
    @Published var currentSessionChunk: Int = 0     /// Index of current chunk (0 or 1): Tracks which 20-min chunk of the session is active
    @Published var sessionHistory: [[TileM]] = []   /// Array of tiles completed in this session of 2 chunks
    @Published var lastError: Error?                /// Used to trigger the UI visual error overlay
    @Published var validationMessages: [String] = []
    
    // MARK: - Internal Properties
    private let config: TimerConfig
    private let tileAppendTrigger: FocusTimerActor
    private var chunkCountdown: Task<Void, Never>? = nil        /// background live time keeper/ticker
    private var sessionCompletionTask: Task<Void, Never>? = nil /// background timer for the entire session (2x 20-min chunks)
    weak var historyVM: HistoryVM?                      /// Link to history view model for/to save completed sessions
    var chunkDuration: Int { config.chunkDuration }     /// Default 20 min chunk duration constant
    
    // MARK: - Cancel or teardown
    deinit {
        chunkCountdown?.cancel()
        sessionCompletionTask?.cancel()
    }
    
    // Preview-friendly Initializer of session state
    init(previewMode: Bool = false, config: TimerConfig = .current) {
        self.config = config
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
        
        /// Cross-actor hop; no 'try' becuase the actor method doesn't throw
        let accepted = await tileAppendTrigger.addTile(newTile)
        guard accepted else { throw FocusSessionError.tooManyTiles(limit: 2) }
        
        tiles.append(newTile)
        tileText = ""
        canAdd = tiles.count < 2       /// Keeps flag in sync

        debugPrint("[FocusSessionVM.addTileAndPrepareForSession.Haptic.notifySuccessfullyAdded] did not occur")
        hapticsEngine.notifySuccessfullyAdded()
    }
    
    /// NOTE: - Swift Concurrency timer (Task + AsyncSequence) needed
    /// Starts the 20-min countdown for the current focus session.
    /// - Throws: `FocusSessionError.tooManyTiles`
    func startCurrent20MinCountdown() throws {
        guard tiles.count <= 2 else {    throw FocusSessionError.tooManyTiles()   }
        
        stopCurrent20MinCountdown()         /// cancels any existing timers
        phase = .running
        countdownRemaining = chunkDuration  /// resets to 20 minutes
        
        chunkCountdown = Task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                guard !Task.isCancelled else {  debugPrint("Countdown task cancelled"); return  }
                if countdownRemaining > 0 { countdownRemaining -= 1; debugPrint("Session countdown: \(formattedTime)")
                } else {    debugPrint("40 min session completed"); break   }
            }
            
            /// Block executes when countdownRemaining reaches 0 or is cancelled
            if self.countdownRemaining <= 0 && self.phase == .running {
                self.phase = .finished
                 hapticsEngine.notifyDone()
                debugPrint("`Haptic.notifyDone()` triggered? Current 20-min chunk completed")
                self.chunkCountdown?.cancel()
                self.chunkCountdown = nil
                naturallyAdvanceSessionChunk()
            }
        }
    }
    
    /// Advances chunk index and checks session completion
    func naturallyAdvanceSessionChunk(){
        currentSessionChunk += 1
        self.checkSessionCompletion()   /// check if chunks session is completed
    }
    
    /// Stops and resets the current countdown timer
    func stopCurrent20MinCountdown() {
        chunkCountdown?.cancel()
        chunkCountdown = nil
        phase = .notStarted
        countdownRemaining = chunkDuration
        debugPrint("Current 20-min countdown stoppped and reset")
    }
    
    // MARK: - Session Lifecycle/Flow
    
    /// Combined Trigger of Chunks Session (via "Begin")
    func beginOverallSession() async throws {
        /// Use the *current* phase for the error payload
        guard tiles.count == 2, phase == .notStarted else {
            debugPrint("Begin pressed and [FocusSessionVM.beginOverallSession] triggered.")
            throw FocusSessionError.invalidBegin(phase: .notStarted, tilesCount: tiles.count)
        }
        await tileAppendTrigger.startSessionTracking()
        sessionActive = true                                /// Overall session activated
        try startCurrent20MinCountdown()                    /// First Chunk started
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
        currentSessionChunk = 0
        await tileAppendTrigger.resetSessionTracking()
        debugPrint("ViewModel state reset for a new session.")
    }
    
   /// Chunks session for completion, triggers recalibration **uses HistoryVM canonical IDs**
    private func checkSessionCompletion() {
        if currentSessionChunk >= 2 {                               /// both chunks done
            sessionActive = false                                   /// 40-min overall session done
            showRecalibrate = true                                  /// modal triggered
            debugPrint("Recalibration choice modal should display")
            /// Bounded tile history call, add tiles to category
            guard let targetCategoryID = historyVM?.generalCategoryID else {
                debugPrint("[FocusSessionVM.checkSessionCompletion] missing historyVM.generalCategoryID"); return
            }
            for tile in tiles.prefix(2){
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
        return String(format: "%02d:%02d", minutes,seconds)
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
    
    
    // MARK: Helpers + Throwing Core
    
    ///Throwing core (async throws): use when the caller wants to decide how to handle the error
}




