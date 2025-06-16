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
    @Published var showRecalibrate: Bool = false
    @Published var countdownRemaining: Int = 1200   // 20 minutes for individual tile task
    @Published var phase: Phase = .notStarted       // State of the *current* 20-min countdown
    @Published var currentSessionChunk: Int = 0     // Tracks which 20-min chunk of the session is active
    
    private let tileAppendTrigger = FocusTimerActor()   // "session timer actor"
    private var countdownPerTile: Task<Void, Never>? = nil
    // This will represent the background timer for the entire session (2x 20-min chunks)
    private var sessionCompletionTask: Task<Void, Never>? = nil
//    
//    func startSession() async {
//        await tileAppendTrigger.startSessionTracking()
//        sessionActive = true
//    }
    // MARK: - Called when "Begin" is tapped for Tiles, is a Swift Concurrency timer (Task + AsyncSequence)
    func startCurrent20MinCountdown() {
        stopCurrent20MinCountdown()  // cancels any existing timers
        phase = .running
        countdownRemaining = 1200   // resets to 20 minutes
        
        countdownPerTile = Task {
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
            
            // Executed when countdownRemaining reaches 0 or is cancelled - phase reset
            if self.countdownRemaining <= 0 && self.phase == .running {
                self.phase = .finished
                // Haptic.notifyDone()
                debugPrint("`Haptic.notifyDone()` triggered? Current 20-min chunk completed")
                self.countdownPerTile?.cancel()
                self.countdownPerTile = nil
            }
        }
    }
    
    func stopCurrent20MinCountdown() {
        countdownPerTile?.cancel()
        countdownPerTile = nil
        phase = .notStarted
        countdownRemaining = 1200   //FIXME: - needed? resets time to 20 for next
        debugPrint("Current 20-min countdown stoppped and reset")
    }
    
    
    func submitTile() async throws {
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
            canAdd = tiles.count < 2
            // Only start the *session* timer when the 2nd tile is added
            if tiles.count == 2 {
                
                await tileAppendTrigger.startSessionTracking()
                sessionActive = true
            }
            // Starts the individual 20-min countdown when 2nd tile is submitted
            startCurrent20MinCountdown()
            checkRecalibrationNeeded()
        } else {
            canAdd = false
        }
    }
    
    // MARK: - Check if overall 40-min session (two 20-min chunks) is complete
    private func checkSessionCompletion() {
        if currentSessionChunk >= 2 {
            sessionActive = false
            showRecalibrate = true
            // Reset actor for new session
            Task {
                await tileAppendTrigger.resetSessionTracking()
                currentSessionChunk = 0
            }
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
            try await submitTile()
        } else {
            // If two tiles are already present, and a countdown just finished,
            // this button could be used to explicitly start the *next* 20-min chunk
            // if the user chose not to immediately continue.
            // For now, based on your description, this button mainly triggers `submitTile`.
            // We might need more explicit UI for "Start next 20-min chunk".
            print("All tiles added. Consider adding logic for starting next chunk explicitly.")
        }
    }
    
    
    func checkRecalibrationNeeded() {
        if tiles.count == 2 {
            showRecalibrate = true
        }
    }
}

