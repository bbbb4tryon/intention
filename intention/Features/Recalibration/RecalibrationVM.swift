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
/// VM is already @MainActor, so the Task {} body runs on the main actor; you can mutate published properties directly (no MainActor.run)
@MainActor
final class RecalibrationVM: ObservableObject {
    enum Phase { case none, idle, running, finished, pause }
    
    @Published private(set) var phase: Phase = .none
    @Published private(set) var mode: RecalibrationMode?
//    @Published private(set) var startedAt: Date?    // part of "snapshotting" the wall-clock to recompute remaining time on re-activation
    @Published private(set) var timeRemaining: Int = 0
    @Published var lastError: Error?
    @Published var breathingPhaseIndex: Int = 0     // 0:Inhale, 1:Hold, 2:Exhale, 3:Hold
    @Published var promptText: String = ""          // “Switch feet” pulses EMOM
    @Published var eyesClosedMode: Bool = false     // UI toggles this before start()
    @Published var balancingPhaseIndex: Int = 0
    
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
    private var balancingMinutes: Int
    private let inhale = 6, hold1 = 3, exhale = 6, hold2 = 3

    private let haptics: HapticsClient
    private var task: Task<Void, Never>?
    @Published private(set) var didHaptic: Set<Int> = []
    
    // Related to time the user backgrounded/spent time outside the app
    private var recalDeadline: Date?
//    private var intendedDuration: Int = 0       // seconds (for .current mode)


    init(haptics: HapticsClient, breathingMinutes: Int = 2, balancingMinutes: Int = 4) {
        self.haptics = haptics
        self.breathingMinutes = min(4, max(2, breathingMinutes))
        self.balancingMinutes = min(4, max(4, balancingMinutes))
    }

    deinit { task?.cancel() }
    
    // MARK: Core API (async throws; View calls these)
    // When starting (not resuming when re-activated after leaving, see `appDidBecomeActive()`):
    func start(mode: RecalibrationMode) async throws {
        cancel()
        self.mode = mode
        self.phase = .running
        
        let mins = (mode == .breathing ? breathingMinutes : balancingMinutes)
        let seconds = mins * 60
        self.timeRemaining = seconds
        self.recalDeadline = Date().addingTimeInterval(TimeInterval(seconds))
        
        switch mode { case .balancing: runBalancing(); case .breathing: runBreathing() }
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
        recalDeadline = nil
    }
    
    func setBreathingMinutes(_ minutes: Int) throws {
        guard (2...4).contains(minutes) else { throw RecalibrationError.invalidBreathingMinutes }
        guard phase != .running else { throw RecalibrationError.cannotChangeWhileRunning }
        breathingMinutes = minutes
    }
    
    func setBalancingMinutes(_ mins: Int) throws {
        guard (1...4).contains(mins) else { throw RecalibrationError.invalidBreathingMinutes }
        guard phase != .running else { throw RecalibrationError.cannotChangeWhileRunning }
        balancingMinutes = mins
    }
    
    
    func appWillResignActive() { /* no-op; wall clock handles it */}
    
    // Resuming when re-activated after leaving, see `start(mode:)`
    // is called un RootView when scene becomes active:
    func appDidBecomeActive() {
        guard phase == .running, let returned = recalDeadline else { return }
        let remain = max(0, Int(returned.timeIntervalSinceNow))
        
        if remain != timeRemaining { timeRemaining = remain }
        if remain == 0 {
            // finish immediately
            phase = .finished
            let finished = mode
            mode = nil
            promptText = ""
            if let m = finished { onCompleted?(m) }
            fireHapticsNotifyDone()
        }
    }
    
    // Pattern to call haptic once per completion
//    private func fireDoneHapticOnce() {
//        guard !didHapticForChunk.contains(currentSessionChunk) else { return }
//        didHapticForChunk.insert(currentSessionChunk)
//        haptics.notifyDone()
//    }
    private func fireHapticsNotifyDone() { haptics.notifyDone() }
    
    
    // MARK: Balancing - short-short every min; long-long-short on done
    private func runBalancing() {
        // Minute beeps: short–short; Done: long–long–short; only show “Switch feet” briefly each minute
        /// cue at start + each minute, set balancingPhaseIndex, optionally show promptText for 1s
        let total = timeRemaining
//        var lastMinBoundary = total
        
        task = Task { [weak self] in
            guard let self else { return }
            var lastCueAt = -1                      // ensure we cue at the start and then each minute boundary
            
            while self.timeRemaining > 0 && !Task.isCancelled {
                // EMOM fire at boundary
                if self.timeRemaining == total || (self.timeRemaining % 60 == 0 && self.timeRemaining != lastCueAt) {
//                    let elapsed = total - self.timeRemaining
//                    let minuteIndex = (elapsed / 60) % 2          // 0,1,0,1...
                    //                    self.haptics.warn()             // short–short
                    haptics.warn()                       // short–short
                    //                    await MainActor.run {
                    //                        self.balancingPhaseIndex = minuteIndex
                    lastCueAt = self.timeRemaining
                    if !self.eyesClosedMode {
                        self.promptText = "Switch feet"
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        self.promptText = ""
                    }
                }
//                        if !self.eyesClosedMode { self.promptText = "Switch feet" }
//                    }
//                    try? await Task.sleep(nanoseconds: 1_000_000_000)
//                    await MainActor.run { self.promptText = "" }
//                    lastCueAt = self.timeRemaining
//                }

                // Tick every second no matter what
                try? await Task.sleep(nanoseconds: 1_000_000_000)
//                await MainActor.run { self.timeRemaining -= 1 }
                self.timeRemaining -= 1
            }

            guard !Task.isCancelled else { return }
            haptics.notifyDone()                // long–long–short
//            await MainActor.run {
                self.phase = .finished
                let finished = self.mode
                self.mode = nil
                self.promptText = ""
                if let m = finished { self.onCompleted?(m) }
//            }
//            await MainActor.run { self.onCompleted?(.balancing) }
        }
    }

    // MARK: Breathing — 6/3/6/3, tiny cue each phase
    private func runBreathing() {
        // Show one line “Inhale · Hold · Exhale · Hold” and move a subtle dot via breathingPhaseIndex
        task = Task { [weak self] in
            guard let self else { return }
            let seq: [(idx: Int, secs: Int)] = [(0, inhale), (1, hold1), (2, exhale), (3, hold2)]
            while self.timeRemaining > 0 && !Task.isCancelled {
                for (idx, secs) in seq {
//                    await MainActor.run {
                        self.breathingPhaseIndex = idx
                        // NOTE: No big label per phase; UI uses breathingPhaseLine + index to draw the dot
//                    }
                    for _ in 0..<secs {
                        guard !Task.isCancelled else { return }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
//                        await MainActor.run { self.timeRemaining = max(0, self.timeRemaining - 1) }
                        self.timeRemaining = max(0, self.timeRemaining - 1)
                        if self.timeRemaining == 0 { break }
                    }
                    if self.timeRemaining == 0 { break }
                    haptics.added()             // tiny cue at phase boundaries
                }
            }
            guard !Task.isCancelled else { return }
            haptics.notifyDone()                // long–long–short
//            await MainActor.run {
                self.phase = .finished
                let finished = self.mode
                self.mode = nil
                self.promptText = ""
                if let m = finished { self.onCompleted?(m) }
//            }
        }
    }

       private func phaseBlock(label: String, seconds: Int) async {
           haptics.added()                          // single short cue at each phase start
           for _ in 0..<seconds {
               guard !Task.isCancelled else { return }
               try? await Task.sleep(nanoseconds: 1_000_000_000)
               await MainActor.run { self.timeRemaining = max(0, self.timeRemaining - 1) }
           }
       }
    
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
}
