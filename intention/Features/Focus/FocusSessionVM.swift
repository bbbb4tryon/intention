//
//  FocusSessionVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
import Foundation

// ViewModel talks to FocusTimerActor and drives the UI

enum FocusSessionError: Error, Equatable {
    case emptyInput
    case tooManyTiles
    case unexpected
    case badTrigger_Overall
}

@MainActor
final class FocusSessionVM: ObservableObject {
    
    enum Phase {
        case notStarted, running, finished
    }
    
    @Published var tileText: String = ""
    @Published var tiles: [TileM] = []
    @Published var canAdd: Bool = true
    @Published var sessionActive: Bool = false      // Overall session state (two 20-min chunks)
    @Published var showRecalibrate: Bool = false    // Drives the .sheet
    @Published var countdownRemaining: Int = 1200   // 20 minutes for individual tile task
    @Published var phase: Phase = .notStarted       // State of the *current* 20-min countdown
    @Published var currentSessionChunk: Int = 0     // Tracks which 20-min chunk of the session is active
    @Published var sessionHistory: [[TileM]] = []   // history model of sessions
    
    private let tileAppendTrigger = FocusTimerActor()
    private var chunkCountdown: Task<Void, Never>? = nil
    private var sessionCompletionTask: Task<Void, Never>? = nil // background timer for the entire session (2x 20-min chunks)
    //
    //    func startSession() async {
    //        await tileAppendTrigger.startSessionTracking()
    //        sessionActive = true
    //    }
    // MARK: - 20-min chunk management - Swift Concurrency timer (Task + AsyncSequence)
    func startCurrent20MinCountdown() {
        stopCurrent20MinCountdown()  // cancels any existing timers
        phase = .running
        countdownRemaining = 1200   // resets to 20 minutes
        
        chunkCountdown = Task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                guard !Task.isCancelled else {
                    debugPrint("Countdown task cancelled")
                    return
                }
                if countdownRemaining > 0 {
                    countdownRemaining -= 1
                    debugPrint("Session countdown: \(formattedTime)")
                } else {
                    debugPrint("40 min session completed")
                    break
                }
            }
            
            // Block executes when countdownRemaining reaches 0 or is cancelled
            if self.countdownRemaining <= 0 && self.phase == .running {
                self.phase = .finished
                // Haptic.notifyDone()      //FIXME: - uncomment when needed
                debugPrint("`Haptic.notifyDone()` triggered? Current 20-min chunk completed")
                self.chunkCountdown?.cancel()
                self.chunkCountdown = nil
                
                // Advance session chunk if finished naturally(?)
                naturallyAdvanceSessionChunk()
            }
        }
    }
    
    func naturallyAdvanceSessionChunk(){
        currentSessionChunk += 1
        self.checkSessionCompletion() // check if chunks session is completed
    }
    
    func stopCurrent20MinCountdown() {
        chunkCountdown?.cancel()
        chunkCountdown = nil
        phase = .notStarted
        countdownRemaining = 1200   //FIXME: - needed? resets time to 20 for next
        debugPrint("Current 20-min countdown stoppped and reset")
    }
    
    // MARK: - Tile submission logic
    // Called by EITHER the "Add" button or keyboard return
    func addTileAndPrepareForSession() async throws {
        // throw, and let the caller decide what to do (including UI, logging, etc.)
        let trimmed = tileText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FocusSessionError.emptyInput
        }
        guard tiles.count < 2 else {
            throw FocusSessionError.tooManyTiles
        }
        
        let tile = TileM(text: trimmed)
        let success = await tileAppendTrigger.addTile(tile) //NOTE: - Initialization of immutable value 'success' was never used; consider replacing with assignment to '_' or removing it... is Dismissed by adding if conditions below
        if success {
            tiles.append(tile)
            tileText = ""
            canAdd = tiles.count < 2    // true if tiles.count is 0 or 1, false if 2
            
            // This is fine; overall session (FocusTimerActor) only truly starts when the "Begin" button is pressed
            
        } else {
            canAdd = false
        }
    }
    
    // MARK: - Combined Trigger of Chunks Session (via "Begin")
    func beginOverallSession() async throws {
        guard tiles.count == 2 && phase == .notStarted else {
            throw FocusSessionError.badTrigger_Overall
            return
        }
        debugPrint("User pressed Begin, overall session and 1st chuck started.")
        await tileAppendTrigger.startSessionTracking()
        sessionActive = true        // Overall session activated
        startCurrent20MinCountdown()    // First Chunk started
    }
    
    // MARK: - Chunks session completion logic
    private func checkSessionCompletion() {
        if currentSessionChunk >= 2 {   // both chunks done
            sessionHistory.append(tiles)    // store completed sessiojn
            sessionActive = false       // 40-min overall session done
            showRecalibrate = true      // modal
            debugPrint("Recalibration choice modal should display")
            // NOTE: - Don't reset actor for new session here - user will on modal
        } else {
            print("""
                  Completed the \(currentSessionChunk)!
                  Well done!
                  On to the next one
                  """)
            // If currentSessionChunk is 1 and phase==finished, the UI will show "Start Next 20 Minutes"
        }
    }
    
    // MARK: - MM:SS helper to format time
    var formattedTime: String {
        let minutes = countdownRemaining / 60
        let seconds = countdownRemaining % 60
        return String(format: "%02d:%02d", minutes,seconds)
    }
    
    // MARK: - function "Begin" button triggers
    func beginSessionFlow() async throws {
        // If no tiles are present, we should allow adding the first one
        // If one tile is present, we should allow adding the second one
        if tiles.count < 2 {
            try await addTileAndPrepareForSession()
        } else {
            // If two tiles are already present, and a countdown just finished,
            // this button could be used to explicitly start the *next* 20-min chunk
            // if the user chose not to immediately continue.
            // For now, based on your description, this button mainly triggers `addTileAndPrepareForSession`.
            // We might need more explicit UI for "Start next 20-min chunk".
            print("All tiles added. Consider adding logic for starting next chunk explicitly.")
        }
    }
    
    
    func checkRecalibrationNeeded() {
        if tiles.count == 2 {
            showRecalibrate = true
        }
    }
    
    // MARK: - Call this when the user decides to start a completely new session cycle
    func resetSessionStateForNewStart() async {
        stopCurrent20MinCountdown() // Ensures any running countdown is stopped
        tiles = []
        tileText = ""
        canAdd = true
        sessionActive = false
        showRecalibrate = false
        currentSessionChunk = 0
        await tileAppendTrigger.resetSessionTracking() // Reset the actor's state too
        debugPrint("ViewModel state reset for a new session.")
    }
}



