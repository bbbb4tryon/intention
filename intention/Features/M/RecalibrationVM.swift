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
    
    @Published var timeRemaining: Int = 240 // seconds
    @Published var instruction: String = ""
    @Published var phase: Phase = .notStarted
    
    private var timer: Timer?
    
    func start(mode: RecalibrationTheme) {
        phase = .running
        timeRemaining = 240
        instruction = mode == .balancing ? "Stand on one foot" : "Inhale"
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { await self?.tick(mode: mode) }
        }
    }
    
    func tick(mode: RecalibrationTheme) async {
        timeRemaining -= 1
        
        if mode == .balancing && timeRemaining % 60 == 0 {
            instruction = "Switch feet"
//            Haptic.notifySwitch()
        } else if mode == .breathing {
            // ?
        }
        
        if timeRemaining <= 0 {
            phase = .finished
            timer?.invalidate()
            timer = nil
//            Haptic.notifyDone()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        phase = .notStarted
    }
}
