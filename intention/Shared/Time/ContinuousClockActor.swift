//
//  ContinuousClockActor.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import Foundation

// VM = “when” (state machine + orchestration + UI/session snapshot), Actor = “how” (monotonic time with ContinuousClock, tick loop, background math, tiny safety snapshot
// session's start time and the tiles that have been added within that session context
// Owns ContinuousClock, tick loop, background/foreground math.
// Supports user pause/resume vs. app background suspend/resume.
// Provides an auxiliary safety snapshot.
actor ContinuousClockActor {
    /// Short debug/UI tests without touching production logic
    // MARK: init
    private let config: TimerConfig
    init(config: TimerConfig) { self.config = config }
    
    // MARK: session state Convenience
    private(set) var sessionStartDate: Date?
    // -- delete currenttiles if no error --
//    private(set) var currentTiles: [TileM] = []     // NOTE: adding = [] dismisses 'has no initializers'
    
    // MARK: Ticking
    private let clock = ContinuousClock()
    // Ticking stops on *backgrounding*, but endInstant keeps track without pausing
    private var tickingTask: Task<Void, Never>?
    // Time keeps elapsing from this
    private var endInstant: ContinuousClock.Instant?
    // Used for *user* paused, not app backgrounding
    private var pausedRemaining: Int?
    
    
    /// Starts a new session window; clears actor's tile buffer.
    // MARK: Session lifecycle (called by VM)
    func startSessionTracking() {
        guard !IS_PREVIEW else { return }
        sessionStartDate = Date()
        // -- delete currenttiles if no error --
        // currentTiles = []           /// Clear tiles for new session
        pausedRemaining = nil
    }
    
    // -- delete this addTile and currenttiles if no error: VM controls --
//    /// Append a tile; returns false if limit (2) already reached.
//    func addTile(_ tile: TileM) -> Bool {
//        guard currentTiles.count < 2 else { return false }
//        currentTiles.append(tile)
//        return true
//    }
    
    func shouldCheckIn() -> Bool {
        guard let start = sessionStartDate else { return false }
        return Date().timeIntervalSince(start) >= Double(config.chunkDuration)      /// Should be 1200 - don't hardcode
    }
    
    func resetSessionTracking() {
        sessionStartDate = nil
        // -- delete currenttiles if no error --
//        currentTiles = []
        cancelTicking()
        endInstant = nil
        pausedRemaining = nil
    }
    
    // MARK: - Ticking control
    func startTicking(
        totalSeconds: Int? = nil,
        onTick: @Sendable @escaping (Int) -> Void,
        onFinish: @Sendable @escaping () -> Void
    ) async {
        guard !IS_PREVIEW else { return }
        cancelTicking()
        
        let total = max(0, totalSeconds ?? config.chunkDuration) // "clamps": UI never shows -00:01
        endInstant = clock.now.advanced(by: .seconds(total))
        
        
        // run the loop on the actor via a private actor-isolated function (tickLoop), the Task only calls into that function
        tickingTask = Task { [weak self] in
            guard let self else { return }
            await self.tickLoop(onTick: onTick, onFinish: onFinish)
        }
    }
    
    // User-initiated pause (unchanged semantics): freezes remaining and clears end
    func pauseTicking(currentRemaining: Int) {
        pausedRemaining = max(0, currentRemaining)      // "clamps": UI never shows -00:01
        cancelTicking()
        endInstant = nil                    // true pause: time stops
    }
    
    // Resume from user pause (unchanged time keeping)
    func resumeTicking(
        onTick:     @Sendable @escaping (Int) -> Void,
        onFinish:   @Sendable @escaping () -> Void
    ) async {
        guard !IS_PREVIEW else { return }
        let resumeFrom = pausedRemaining ?? secondsRemaining() ?? config.chunkDuration
        pausedRemaining = nil
        await startTicking(totalSeconds: resumeFrom, onTick: onTick, onFinish: onFinish)
    }
    
    func suspendForBackground(){
        // App background: stop work but KEEP endInstant so wall time keeps elapsing.
        // endInstant remains set; the key difference vs a user pause
        cancelTicking()
    }
    
    // Foreground: compute remaining using endInstant and, either finish or  return nil
    func remainingAfterForeground() async -> Int? {
        guard let end = endInstant else { return pausedRemaining }
        // let now = clock.now
        // return max(0, Int(ceil(end.duration(to: now).magnitude.seconds)))
        return remainingSeconds(to: end)
    }
    
    func secondsRemaining() -> Int? {
        guard let end = endInstant else { return pausedRemaining }
        return remainingSeconds(to: end)
    }
    
    // MARK: actor-isolated tickLoop
    private func tickLoop(
        onTick:     @Sendable (Int) -> Void,
        onFinish:   @Sendable () -> Void
    ) async {
        // a guard against any bug in 'secs' that misreads to count upwards and now a countdown
        var lastEmitted = -1
        while !Task.isCancelled {
            // Sleep to the next second boundary
            guard let end = endInstant else { break }
            let secs = remainingSeconds(to: end)
            if secs != lastEmitted {
                lastEmitted = secs
                onTick(secs)
            }
            if secs == 0 { break }
            try? await clock.sleep(for: .seconds(1))
        }
        if !Task.isCancelled { onFinish() }
    }
    
    // Use this helper anywhere you derive remaining time so it’s consistent and non-negative
    private func remainingSeconds(to end: ContinuousClock.Instant) -> Int {
        let dur = clock.now.duration(to: end)                   // positive if end in the future
        let secs = Int(ceil(Double(dur.components.seconds)))    // ignore attoseconds; 1 Hz UI
        return max(0, secs)                                     // "clamps": UI never shows -00:01
    }
    
    private func cancelTicking(){
        tickingTask?.cancel()
        tickingTask = nil
    }
    
    // MARK: Auxiliary safety snapshot
    //    Why: App background suspends your task, not wall-clock time. Keeping endInstant lets you recompute exactly how much time passed while the app was away.
    // Optional: still keep snapshot if you like; not strictly required if endInstant persists in memory.
    struct Snapshot: Codable, Sendable {
        let sessionStartEpoch: TimeInterval
        let remainingSeconds: Int
        let capturedAtEpoch: TimeInterval
    }
    
    func makeSnapshot() -> Snapshot? {
        guard let start = sessionStartDate else { return nil }
        let remaining = (secondsRemaining()) ?? config.chunkDuration
        return Snapshot(
            sessionStartEpoch: start.timeIntervalSince1970,
            remainingSeconds: remaining,
            capturedAtEpoch: Date().timeIntervalSince1970
        )
    }
    
    func restoreFromSafetySnapshot(_ snap: Snapshot) {
        sessionStartDate = Date(timeIntervalSince1970: snap.sessionStartEpoch)
        pausedRemaining = snap.remainingSeconds
        endInstant = nil
        cancelTicking()
    }
}
