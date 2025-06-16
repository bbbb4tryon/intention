//
//  RecalibrationVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import Foundation

@MainActor
final class RecalibrationVM: ObservableObject {
    enum Phase {
        case notStarted, running, finished
    }
    
    @Published var timeRemaining: Int = 240 // 4 min
    @Published var instruction: String = ""
    @Published var phase: Phase = .notStarted
    
    private var countdownTask: Task<Void, Never>? = nil
    
    //  starts a true Swift Concurrency timer - Task + AsyncSequence
    //      clean, cancelable and lives in the actor context
    func start(mode: RecalibrationTheme) {
        stop()      // cancels any existing timer
        phase = .running
        timeRemaining = 240
        instruction = mode == .balancing ? "Stand on one foot" : "Inhale"
        
        countdownTask = Task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                await tick(mode: mode)
                if timeRemaining <= 0 { break }
            }
        }
    }
    
    func tick(mode: RecalibrationTheme) async {
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            phase = .finished
            Haptic.notifyDone()
            countdownTask?.cancel()
            countdownTask = nil
            return
        }
        
        if mode == .balancing && timeRemaining % 60 == 0 {
            instruction = "Switch feet"
            Haptic.notifySwitch()
        } else if mode == .breathing {
            // ? animate or alternate phases (inhale, pause, etc)
        }
        
    }
    
    func stop() {
        countdownTask?.cancel()
        countdownTask = nil
        phase = .notStarted
    }
}
