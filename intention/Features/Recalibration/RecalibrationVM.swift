//
//  RecalibrationVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import Foundation

enum RecalibrationError: Error, Equatable, LocalizedError {
    case alreadyActive
    case notActive
    case invalidType
    case persistenceFailed
    case unexpected

    var errorDescription: String? {
        switch self {
        case .alreadyActive: return "Recalibration is already active."
        case .notActive: return "No recalibration is running."
        case .invalidType: return "Unsupported recalibration type."
        case .persistenceFailed: return "Couldn’t save your recalibration."
        case .unexpected: return "Something went wrong. Please try again."
        }
    }
}


@MainActor
final class RecalibrationVM: ObservableObject {
    enum Phase {
        case notStarted, running, finished
    }
    
    @Published var timeRemaining: Int = 240 // 4 min
    @Published var instruction: String = ""
    @Published var phase: Phase = .notStarted
    
    private let config: TimerConfig
    private var countdownTask: Task<Void, Never>? = nil
    private let persistence: PersistenceActor?
    
    init(config: TimerConfig = .current, persistence: PersistenceActor? = nil) {
        self.config = config
        self.timeRemaining = config.recalibrationDuration
        self.persistence = persistence
    }
    
    // MARK: - Cancel or teardown
    deinit {
        countdownTask?.cancel()
    }
    
    //  starts a true Swift Concurrency timer - Task + AsyncSequence
    ///      clean, cancelable and lives in the actor context
    func start(mode: RecalibrationType) {
        stop()          /// cancels any existing timer
        phase = .running
        timeRemaining = config.recalibrationDuration
        instruction = mode == .balancing ? "Stand on one foot" : "Inhale"
        
        countdownTask = Task {
            for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
                await tick(mode: mode)
                if timeRemaining <= 0 { break } // exit loop when time runs out
            }
        }
    }
    
    func tick(mode: RecalibrationType) async {
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
    
//    FIXME: USE THESE OR START() STOP()?
//    func begin(_ type: RecalibrationType) async throws {
//        guard !isActive else { throw RecalibrationError.alreadyActive }
//        currentType = type
//        secondsRemaining = duration(for: type)
//        isActive = true
//
//        // Launch the ticking loop (owned by VM; cancel in deinit)
//        startCountdownLoop()
//    }
//
//    func cancel() async throws {
//        guard isActive else { throw RecalibrationError.notActive }
//        countdownTask?.cancel()
//        countdownTask = nil
//        isActive = false
//        currentType = nil
//        secondsRemaining = 0
//    }
//    
//    func logCompletionIfPossible() {
//        guard let persistence else { return }
//        Task {
//            do {
//                // Replace with your model/record; using a trivial struct for example
//                struct RecalibrationRecord: Codable { let date: Date; let kind: String; let duration: Int }
//                let kind = kindString(currentType)
//                let rec = RecalibrationRecord(date: Date(), kind: kind, duration: secondsRemaining)
//                try await persistence.saveHistory([rec], to: "recalibrationLog")
//            } catch {
//                debugPrint("[RecalibrationVM.logCompletionIfPossible] error:", error)
//                self.lastError = RecalibrationError.persistenceFailed
//            }
//        }
//    }
//    // MARK: Internals
//
//      private func startCountdownLoop() {
//          countdownTask?.cancel()
//          let total = secondsRemaining
//          countdownTask = Task {
//              do {
//                  for sec in stride(from: total, through: 0, by: -1) {
//                      try Task.checkCancellation()
//                      await MainActor.run { self.secondsRemaining = sec }
//                      try await Task.sleep(nanoseconds: 1_000_000_000)
//                  }
//                  await MainActor.run {
//                      self.isActive = false
//                  }
//                  Haptic.notifyDone()
//                  // background log (non-blocking)
//                  self.logCompletionIfPossible()
//              } catch is CancellationError {
//                  // Swallow
//              } catch {
//                  await MainActor.run {
//                      self.lastError = RecalibrationError.unexpected
//                      self.isActive = false
//                  }
//              }
//          }
//      }
//
//      private func duration(for type: RecalibrationType) -> Int {
//          switch type {
//          case .breathe(let s): return max(5, s)
//          case .balance(let s): return max(5, s)
//          }
//      }
//
//      private func kindString(_ type: RecalibrationType?) -> String {
//          guard let type else { return "none" }
//          switch type {
//          case .breathe: return "breathe"
//          case .balance: return "balance"
//          }
//      }
//  }
//
    // Helper to format time into MM:SS
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
