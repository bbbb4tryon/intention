//
//  RecalibrationVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import Foundation

// case persistenceFailed(underlying: Error)
enum RecalibrationError: Error, Equatable, LocalizedError {
    case alreadyActive
    case notActive
    case invalidType
    case persistenceFailed
    case unexpected

    var errorDescription: String? {
        switch self {
        case .alreadyActive: return "Recalibration is already active."
        case .notActive: return "No recalibration is active."
        case .invalidType: return "Unsupported recalibration type."
        case .persistenceFailed: return "Couldn’t save that recalibration."
        case .unexpected: return "Something went wrong. Please try again."
        }
    }
}


@MainActor
final class RecalibrationVM: ObservableObject {
    
    // MARK: Phase
    enum Phase {
        case notStarted, running, finished
    }

//    struct rTimerConfig: Sendable {
//        var breathingDuration: Int = 30         /// Seconds
//        var balancingDuration: Int = 60         /// Seconds
//        var breathingCueInterval: Int = 16      /// Seconds
//        var balanceSwitchInterval: Int = 60     /// Seconds
//    }
    
    // MARK: State
    @Published var phase: Phase = .notStarted
    @Published var timeRemaining: Int = 0
    @Published var mode: RecalibrationMode? = nil
    @Published var instruction: String = ""
    @Published var lastError: Error? = nil
    
    /// Exposed read-only for views/tests that want to show the configured durations
    let config: TimerConfig             // NOT TimerConfig?
    
    private let persistence: PersistenceActor?
    private var countdownTask: Task<Void, Never>? = nil
    
    /// Session-scoped trackers
    private var sessionTotal: Int = 0
    private var halfwayAnnounced = false
    private var lastSwitchAnnouncementAt: Int = .max
    private var lastCountdownTickAt: Int = -1
    
    // MARK: Lifecycle
    
    init(config: TimerConfig = .current, persistence: PersistenceActor? = nil) {
        self.config = config
        self.persistence = persistence
    }
    
    // MARK: - Cancel or teardown
    deinit {
        countdownTask?.cancel()
    }
    
    // MARK: Core API (async throws; View calls these)
    //  starts a true Swift Concurrency timer - Task + AsyncSequence
    /// clean, cancelable and lives in the actor context
    /// Starts a recalibration sesison for a given type
    func start(mode: RecalibrationMode) async throws {
        guard phase != .running else {  throw RecalibrationError.alreadyActive   }
        
        let duration = duration(for: mode)
        guard duration > 0 else { throw RecalibrationError.invalidType  }
        
        self.mode = mode
        self.sessionTotal = duration
        self.timeRemaining = duration
        self.phase = .running

        /// Reset session markers
        self.halfwayAnnounced = false
        self.lastSwitchAnnouncementAt = duration
        self.lastCountdownTickAt = -1
        
        startCountdownLoop()
        
//        countdownTask = Task {
//            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
//                await tick(mode: mode)
//                if timeRemaining <= 0 { break } // exit loop when time runs out
//            }
//        }
    }
    
    /// Stops current recalibration session
    func stop() async throws {
        guard phase == .running else {  throw RecalibrationError.notActive   }
        countdownTask?.cancel()
        countdownTask = nil
        self.phase = .notStarted
        self.mode = nil
        self.timeRemaining = 0
    }
    
    // MARK: Non-throwing wrappers (for background/auto callers)
    
    /// Non-throwing convenience that captures errors into 'lastError`
    func startSafely(mode: RecalibrationMode) {
        Task {
            do { try await start(mode: mode)    }
            catch {
                debugPrint("[RecalibrationVM.startSafely] error: ", error.localizedDescription)
                self.lastError = error
            }
        }
    }
    
    /// Non-throwing convenience that captures errors into `lastError`.
    func stopSafely() {
        Task {
            do   { try await stop() }
            catch {
                debugPrint("[RecalibrationVM.stopSafely]", error.localizedDescription)
                self.lastError = error
            }
        }
    }
    
    // MARK: Private helpers
    
      private func startCountdownLoop() {
          countdownTask?.cancel()
          
          let total = timeRemaining
          countdownTask = Task { [weak self] in
              guard let self else { return }
              do {
                  var remaining = total
                  while remaining > 0 {
                      try Task.checkCancellation()
                      try await Task.sleep(nanoseconds: 1_000_000_000) // 1s

                      remaining -= 1
                      await MainActor.run {
                          self.timeRemaining = remaining
                          self.maybeHalfwayHaptic(remaining: remaining, total: total)
                          self.maybeSwapHaptic(remaining: remaining)
                          self.maybeEndCountdownHaptic(remaining: remaining)
//                          self.maybeAnnounceSwitchIfNeeded(remaining: remaining)
                      }
                  }

                  await MainActor.run {
                      self.phase = .finished
                  }
                  Haptic.notifyDone()

                  /// Background log; errors are captured silently or into lastError on main.
                  await self.logCompletionIfPossible(duration: total)

                  await MainActor.run {
                      /// Reset back to idle after finishing
                      self.mode = nil
                      self.timeRemaining = 0
                  }
              } catch is CancellationError {
                  // user canceled; ignore
              } catch {
                  await MainActor.run {
                      self.lastError = RecalibrationError.unexpected
                      self.phase = .notStarted
                  }
              }
          }
      }
    
    private func duration(for mode: RecalibrationMode) -> Int {
        switch mode {
        case .balancing: return max(5, config.balancingDuration)
        case .breathing: return max(5, config.breathingDuration)
        }
    }
    
    
    // MARK: Haptic helpers
    
    private func maybeHalfwayHaptic(remaining: Int, total: Int) {
        guard config.haptics.halfwayTick, total > 1 else {  return  }
        let halfway = total / 2
        if !halfwayAnnounced && remaining == halfway {
            halfwayAnnounced = true
            Haptic.halfway()
        }
    }
    
    private func maybeSwapHaptic(remaining: Int) {
        guard mode == .balancing, config.haptics.balanceSwapInterval > 0 else { return }
        // Count-down based interval: fire when remaining % interval == 0 (avoid duplicates with tracker).
        if remaining > 0,
           remaining % config.haptics.balanceSwapInterval == 0,
           remaining != lastSwitchAnnouncementAt {
            lastSwitchAnnouncementAt = remaining
            Haptic.notifySwitch()
        }
    }
    
//    private func maybeAnnounceSwitchIfNeeded(remaining: Int) {
//        guard mode == .balancing, config.haptics. > 0 else { return }
//        /// Fire a light haptic each interval (counting down).
//        if (remaining > 0) && (remaining % config.balanceSwitchInterval == 0) && (remaining != lastSwitchAnnouncementAt) {
//            lastSwitchAnnouncementAt = remaining
//            Haptic.notifySwitch()
//        }
//    }
    
    private func maybeEndCountdownHaptic(remaining: Int) {
        let start = config.haptics.endCountdownStart
        guard start > 0, remaining > 0, remaining <= start else { return }
        /// Tick once per second near the end; avoid duplicate if this method runs multiple times a second.
        if lastCountdownTickAt != remaining {
            lastCountdownTickAt = remaining
            Haptic.countdownTick()
        }
    }
    
    private func logCompletionIfPossible(duration: Int) async {
        guard let persistence else { return }
        struct RecalibrationRecord: Codable {
            let date: Date
            let mode: String
            let duration: Int
        }
        let record = RecalibrationRecord(
            date: .now,
            mode: {
                switch mode {
                case .breathing?: return "breathing"
                case .balancing?: return "balancing"
                default: return "none"
                }
            }(),
            duration: duration
        )

        await Task.detached(priority: .background) {
            do {
                try await persistence.write([record], to: "recalibrationLog")
            } catch {
                await MainActor.run {
                    /// Optional: surface this as a typed error
                    self.lastError = RecalibrationError.persistenceFailed
                }
            }
        }.value
    }
    
    // Helper to format time into MM:SS
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
