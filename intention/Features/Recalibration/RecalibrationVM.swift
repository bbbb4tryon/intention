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
        case .invalidBreathingMinutes:   return "Timing is preset."
        case .cannotChangeWhileRunning:  return "You can’t change duration while a session is running."
        }
    }
}

/// One entry point: start(mode:)
/// VM decides duration + cadence (no durations in the View).
/// Haptics are triggered from VM only (View stays quiet).
/// Swift-6 friendly captures; cancel on deinit.

/* Why MainActor.run at all if RecalibrationVM is @MainActor? */

/// VM is @MainActor, but loop work runs in a Task on a background executor.
/// We touch @Published state only inside MainActor.run { ... } blocks.

@MainActor
final class RecalibrationVM: ObservableObject {
    enum Phase { case none, idle, running, finished, pause }
    
    @Published private(set) var phase: Phase = .none
    @Published private(set) var mode: RecalibrationMode?
//    @Published private(set) var startedAt: Date?    // part of "snapshotting" the wall-clock to recompute remaining time on re-activation
    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var totalDuration: Int = 0  // of time bar
    @Published var lastError: Error?
    @Published var breathingPhaseIndex: Int = 0     // 0:Inhale, 1:Hold, 2:Exhale, 3:Hold
    @Published var eyesClosedMode: Bool = false     // UI toggles this before start()
    @Published var balancingPhaseIndex: Int = 0
    
    var formattedTime: String {
        TimeString.mmss(timeRemaining)
    }
    
    // Counts
    var onCompleted: ((RecalibrationMode) -> Void)?
    
    // VMs current default on present
    var currentBreathingMinutes: Int { breathingMinutes }
    var currentBalancingMinutes: Int { balancingMinutes }
    
    // Prompts
    let breathingPhases = ["Inhale", "Hold", "Exhale", "Hold"]
    
    // Policy knobs (VM decides "when")
    private var breathingMinutes: Int
    private var balancingMinutes: Int
    private let inhale = 4, hold1 = 3, exhale = 6, hold2 = 3

    private let haptics: HapticsClient
    private let actor = ContinuousClockActor(config: .current) // reuse same actor type
     
    private var task: Task<Void, Never>?
    @Published private(set) var didHaptic: Set<Int> = []
    
    // Related to time the user backgrounded/spent time outside the app
    private var recalDeadline: Date?
    private var intendedDuration: Int = 0       // duration - related to time bar

    init(haptics: HapticsClient, breathingMinutes: Int = 2, balancingMinutes: Int = 4) {
        self.haptics = haptics
        self.breathingMinutes = min(4, max(2, breathingMinutes))
        self.balancingMinutes = min(4, max(1, balancingMinutes))
    }

    deinit { task?.cancel() }
    
    // MARK: Core API (async throws; View calls these)
    // When starting (not resuming when re-activated after leaving, see `appDidBecomeActive()`):
    func start(mode: RecalibrationMode, duration: Int = TimerConfig.current.recalibrationDuration) async throws {
        cancel()
        self.mode = mode
        self.phase = .running

        await actor.startTicking(
            totalSeconds: duration,
            onTick: {_ in },
            // makes .finished immediately settle into .idle
            onFinish: { [weak self] in
                Task { @MainActor in
//                    self?.phase = .finished
                    self?.haptics.notifyDone()
                    self?.phase = .idle
                    self?.mode = nil
                }
            }
        )
        
        let mins = (mode == .breathing ? breathingMinutes : balancingMinutes)
        let seconds = mins * 60
        
        self.intendedDuration = seconds
        self.totalDuration = seconds
        self.timeRemaining = seconds
        self.recalDeadline = Date().addingTimeInterval(TimeInterval(seconds))
        
        // Reset phase indices and prompt on each start
//        self.promptText = ""
        self.breathingPhaseIndex = 0
        self.balancingPhaseIndex = 0
        
        
        switch mode {
        case .balancing: runBalancing()
        case .breathing: runBreathing()
        }
    }
    
    func stop() async throws {
        cancel()
        phase = .idle
        mode = nil
//        promptText = ""
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
        let remain = max(0, Int(returned.timeIntervalSinceNow))         // "clamps": UI never shows -00:01
        
        if remain != timeRemaining { timeRemaining = remain }
        if remain == 0 {
            // finish immediately
//            phase = .finished
            phase = .idle
            let finished = mode
            mode = nil
//            promptText = ""
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
    private func fireHapticsNotifyDone() {
        haptics.notifyDone()
        haptics.notifyDone()
    }
    

    // MARK: Balancing - short cues every minute; long–long–short on done
    private func runBalancing() {
        // Capture the starting time so we can compute elapsed minutes.
        let totalAtStart = timeRemaining

        task = Task { [weak self] in
            guard let self else { return }

            // Tracks which minute we’ve already fired a cue for.
            // -1 means “none yet”.
            var lastMinuteCued: Int = -1

            while true {
                // Snapshot remaining time on the main actor.
                let remaining = await MainActor.run { self.timeRemaining }

                // Exit if cancelled or time has fully elapsed.
                if Task.isCancelled || remaining <= 0 {
                    break
                }

                // Compute how many seconds have elapsed since start.
                let elapsed       = totalAtStart - remaining
                let currentMinute = elapsed / 60   // 0, 1, 2, ...

                // Fire cue ON the minute, but:
                // - only once per minute
                // - never on minute 0 (skip start)
                if currentMinute > 0 && currentMinute != lastMinuteCued {
                    lastMinuteCued = currentMinute

                    await MainActor.run {
                        // Alternate which “side” is active (0 ↔ 1).
                        self.balancingPhaseIndex = currentMinute % 2

                        // Tactile bump, bump, bump when it’s time to switch.
                        self.haptics.added()
                        self.haptics.added()
                        self.haptics.added()
                        // No promptText now – BalanceSideDots does the visual work.
                    }

                    #if !os(watchOS)
                    // Let the user feel/see the cue for a moment before the next tick.
                    try? await Task.sleep(for: .seconds(0.8))
                    #endif
                }

                // Tick every second, counting down.
                try? await Task.sleep(for: .seconds(1))

                await MainActor.run {
                    // Clamp to 0 so the UI never shows -00:01.
                    self.timeRemaining = max(0, self.timeRemaining - 1)
                }
            }

            // If cancelled at any point, don't run "finished" logic.
            guard !Task.isCancelled else { return }

            // Finish + notify exactly once, on the main actor.
            await MainActor.run {
                self.fireHapticsNotifyDone()          // long–long–short
//                self.phase = .finished
                self.phase = .idle
                let finishedMode = self.mode
                self.mode = nil
//                self.promptText = ""
                if let m = finishedMode {
                    self.onCompleted?(m)
                }
            }
        }
    }


    // MARK: Breathing — 4/4/4/4, tiny cue each phase
    private func runBreathing() {
        
        let phases: [(idx: Int, secs: Int)] = [
            (0, inhale),
            (1, hold1),
            (2, exhale),
            (3, hold2)
        ]
        
        // Show one line “Inhale · Hold · Exhale · Hold” and move a subtle dot via breathingPhaseIndex
        task = Task { [weak self] in
            guard let self else { return }
            
            while true {
                let remaining = await MainActor.run { self.timeRemaining }
                if Task.isCancelled || remaining <= 0 {
                    break
                }
                
                for (idx, secs) in phases {
                    // set active phase index on the main actor
                    await MainActor.run {
                        // NOTE: No big label per phase; UI uses breathingPhaseLine + index to draw the dot
                        self.breathingPhaseIndex = idx
                    }
                    
                    for _ in 0..<secs {
                        let remainingInner = await MainActor.run { self.timeRemaining }
                        if Task.isCancelled || remainingInner <= 0 { break }
                        
                        try? await Task.sleep(for: .seconds(1))
                        
                        await MainActor.run {
                            self.timeRemaining = max(0, self.timeRemaining - 1)
                        }
                    }
                    
                    if Task.isCancelled { return }
                    
                    let afterPhaseRemaining = await MainActor.run { self.timeRemaining }
                    if afterPhaseRemaining <= 0 {
                        break
                    }
                    
                    await MainActor.run {
                        // phase boundary cue
                        self.haptics.added(); self.haptics.added(); self.haptics.added()
                    }
                }
            }
            
            guard !Task.isCancelled else { return }
            
            // all the “we’re finished” work in a single block
            await MainActor.run {
                self.fireHapticsNotifyDone()
//                self.phase = .finished
                self.phase = .idle
                let finishedMode = self.mode
                self.mode = nil
//                self.promptText = ""
                if let m = finishedMode { self.onCompleted?(m) }
            }
//            
//            let seq: [(idx: Int, secs: Int)] = [(0, inhale), (1, hold1), (2, exhale), (3, hold2)]
//            while self.timeRemaining > 0 && !Task.isCancelled {
//                for (idx, secs) in seq {
////                    await MainActor.run {
//                        self.breathingPhaseIndex = idx
//                        
////                    }
//                    for _ in 0..<secs {
//                        guard !Task.isCancelled else { return }
//                        try? await Task.sleep(for: .seconds(1))
////                        await MainActor.run { self.timeRemaining = max(0, self.timeRemaining - 1) }
//                        self.timeRemaining = max(0, self.timeRemaining - 1) // "clamps": UI never shows -00:01
//                        if self.timeRemaining == 0 { break }
//                    }
//                    if self.timeRemaining == 0 { break }
//                    haptics.added()             // tiny cue at phase boundaries
//                }
//            }
//            guard !Task.isCancelled else { return }
//            haptics.notifyDone()                // long–long–short
////            await MainActor.run {
//                self.phase = .finished
//                let finished = self.mode
//                self.mode = nil
//                self.promptText = ""
//                if let m = finished { self.onCompleted?(m) }
////            }
            
        }
    }

//       private func phaseBlock(label: String, seconds: Int) async {
//           haptics.added()                          // single short cue at each phase start
//           for _ in 0..<seconds {
//               guard !Task.isCancelled else { return }
//               try? await Task.sleep(for: .seconds(1))
//               await MainActor.run { self.timeRemaining = max(0, self.timeRemaining - 1) }  // "clamps": UI never shows -00:01
//           }
//       }
    
    func performAsyncAction(_ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
            } catch {
                debugPrint("[FocusVM.performAsyncAction] error:", error)
                self.lastError = error
            }
        }
    }
}

#if DEBUG
@MainActor
extension RecalibrationVM {
    /// Debug-only setters; returning Self enables fluent build-up in previews.
    @discardableResult func _debugSetPhase(_ p: Phase) -> Self { self.phase = p; return self }
    @discardableResult func _debugSetMode(_ m: RecalibrationMode?) -> Self { self.mode = m; return self }

    /// Canonical preview factory: shows a running breathing session with a visible countdown.
    static func mockForDebug() -> RecalibrationVM {
        let vm = RecalibrationVM(
            haptics: NoopHapticsClient(),
            breathingMinutes: 1,
            balancingMinutes: 1
        )
        vm._debugSetMode(.breathing)
          ._debugSetPhase(.running)
        vm.totalDuration = 90
        vm.timeRemaining = 17 // 1:30 gives a nice visual
        return vm
    }
}
#endif
