//
//  RecalibrationVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import Foundation

enum RecalibrationError: LocalizedError {
    case invalidBreathingMinutes, cannotChangeWhileRunning
    var errorDescription: String? {
        switch self {
        case .invalidBreathingMinutes:   return "Breathing must be 2–4 minutes."
        case .cannotChangeWhileRunning:  return "You can’t change duration while a session is running."
        }
    }
}

/// One entry point: start(mode:)

/// VM decides duration + cadence (no durations in the View).

/// Haptics are triggered from VM only (View stays quiet).

/// Swift-6 friendly captures; cancel on deinit.
@MainActor
final class RecalibrationVM: ObservableObject {
    enum Phase { case idle, running, finished }
    
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var mode: RecalibrationMode? = nil
    @Published var timeRemaining: Int = 0
    @Published var lastError: Error? = nil
    @Published var promptText: String = ""  // “Switch feet” pulses EMOM
    @Published var breathingPhaseIndex: Int = 0 // 0:Inhale, 1:Hold, 2:Exhale, 3:Hold
    
    var formattedTime: String {
        let m = timeRemaining / 60, s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // Counts
    var onCompleted: ((RecalibrationMode) -> Void)?
    
    // VMs current default on present
    var currentBreathingMinutes: Int { breathingMinutes }
    var currentBalancingMinutes: Int { balancingMinutes }
    
    // Prompts
    let breathingPhases = ["Inhale", "Hold", "Exhale", "Hold"]
    var breathingPhaseLine: String { breathingPhases.joined(separator: " . ") }

    // Policy knobs (VM decides "when")
    private var breathingMinutes: Int
    private let balancingMinutes: Int
    private let inhale = 6, hold1 = 3, exhale = 6, hold2 = 3

    private let haptics: HapticsClient
    private var task: Task<Void, Never>?

    init(haptics: HapticsClient,
         breathingMinutes: Int = 2,
         balancingMinutes: Int = 4)
    {
        self.haptics = haptics
        self.breathingMinutes = min(4, max(2, breathingMinutes))
        self.balancingMinutes = balancingMinutes
    }

    deinit { task?.cancel() }

    
    // MARK: Core API (async throws; View calls these)
    func setBreathingMinutes(_ minutes: Int) throws {
        guard (2...4).contains(minutes) else { throw RecalibrationError.invalidBreathingMinutes }
        guard phase != .running else { throw RecalibrationError.cannotChangeWhileRunning }
        breathingMinutes = minutes
    }
    
    func start(mode: RecalibrationMode) async throws {
        cancel()
        self.mode = mode
        self.phase = .running
        switch mode {
        case .balancing:
            timeRemaining = balancingMinutes * 60
            runBalancing()
        case .breathing:
            timeRemaining = breathingMinutes * 60
            runBreathing()
        }
    }
    func stop() async throws {
        cancel()
        phase = .idle
        mode = nil
        promptText = ""
    }

    private func cancel() {
        task?.cancel()
        task = nil
    }
    
    // MARK: Private helpers
    private func runBalancing() {
        // Minute beeps: short–short; Done: long–long–short; only show “Switch feet” briefly each minute
        let total = timeRemaining
        task = Task { [weak self] in
            guard let self else { return }
            while self.timeRemaining > 0 && !Task.isCancelled {
                if self.timeRemaining == total || self.timeRemaining % 60 == 0 {
                    await self.haptics.notifySwitch()      // short–short
                    await MainActor.run {
                        self.promptText = "Switch feet"
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // show for ~1s
                    await MainActor.run { self.promptText = "" }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { self.timeRemaining -= 1 }
            }
            guard !Task.isCancelled else { return }
            await self.haptics.notifyDone() // long–long–short
            await MainActor.run {
                self.phase = .finished
                self.mode = nil
                self.promptText = ""
            }
            await MainActor.run { self.onCompleted?(.balancing) }
        }
    }

    private func runBreathing() {
        // Show one line “Inhale · Hold · Exhale · Hold” and move a subtle dot via breathingPhaseIndex
        task = Task { [weak self] in
            guard let self else { return }
            let phases = [(0, inhale), (1, hold1), (2, exhale), (3, hold2)]
            while self.timeRemaining > 0 && !Task.isCancelled {
                for (idx, secs) in phases {
                    await MainActor.run {
                        self.breathingPhaseIndex = idx
                        // NOTE: No big label per phase; UI uses breathingPhaseLine + index to draw the dot
                    }
                    for _ in 0..<secs {
                        guard !Task.isCancelled else { return }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await MainActor.run { self.timeRemaining = max(0, self.timeRemaining - 1) }
                        if self.timeRemaining == 0 { break }
                    }
                    if self.timeRemaining == 0 { break }
                    await self.haptics.added() // tiny cue at phase boundaries
                }
            }
            guard !Task.isCancelled else { return }
            await self.haptics.notifyDone() // long–long–short
            await MainActor.run {
                self.phase = .finished
                let finished = self.mode
                self.mode = nil
                self.promptText = ""
                if let m = finished { self.onCompleted?(m) }
            }
        }
    }


       private func phaseBlock(label: String, seconds: Int) async {
           await haptics.added()   // single short cue at each phase start
           for _ in 0..<seconds {
               guard !Task.isCancelled else { return }
               try? await Task.sleep(nanoseconds: 1_000_000_000)
               await MainActor.run { self.timeRemaining = max(0, self.timeRemaining - 1) }
           }
       }
}
