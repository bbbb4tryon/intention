//
//  StatsVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/30/25.
//

import Foundation
import SwiftUI

enum StatsError: Error, Equatable, LocalizedError {
    case calculationFailed
    
    var errorDescription: String? {
        switch self {
        case .calculationFailed: return "Calculation failed."
        }
    }
}

@MainActor
final class StatsVM: ObservableObject {
    @Published private(set) var averageCompletionRate: Double = 1.0
    @Published private(set) var totalCompletedIntentions: Int = 0
    @Published private(set) var recalibrationCounts: [RecalibrationMode: Int] = [:] // what?
    @Published private(set) var lastRecalibrationChoice: RecalibrationMode?
    @Published private(set) var streak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published var shouldPromptForMembership: Bool = false  // is good flag
    @Published var lastError: Error?
    
    private let persistence: any Persistence
    private let storageKey = "completedSessions"
    private let membershipThreshold = 2
    private var completedSessions: [CompletedSession] = []
    
    weak var memVM: MembershipVM?
    
    init(persistence: any Persistence) {
        self.persistence = persistence
        Task {  await loadSessions()    }
    }
    
    func logSession(_ session: CompletedSession) {
        completedSessions.append(session)
        // Update intention count
        totalCompletedIntentions = completedSessions.flatMap(\.tileTexts).count
        memVM?.triggerPromptIfNeeded(afterSessions: completedSessions.count)
        
        /// if user did recalibrate (picked breathing or balancing), type will be non-nil, and count incremented
        if let type = session.recalibration {
            recalibrationCounts[type, default: 0] += 1
            lastRecalibrationChoice = type
        }
        
        recalculateStats()
        
        /// Updates to trigger membership prompt ($0.99 then $5.99 for 3 months?)
        /// Keeps onboarding friction at zero: the user never types anything.
        if completedSessions.count == membershipThreshold {
            shouldPromptForMembership = true    // Observe in the RootView and present as alert/sheet
        }
        
        Task {
            do {
                try await persistence.write(completedSessions, to: storageKey)
            } catch {
                debugPrint("[StatsVM.logSession persistence.saveHistory] error:", error)
                await MainActor.run { self.lastError = error }
            }
        }
    }
    
    private func loadSessions() async {
        do {
            if let loaded: [CompletedSession] = try await persistence.readIfExists([CompletedSession].self, from: storageKey) {
                completedSessions = loaded
                recalculateStats()
            }
        } catch {
            debugPrint("[StatsVM.loadSessions] from PersistenceActor: ", error)
            await MainActor.run { self.lastError = error }
        }
    }
    private func recalculateStats() {
        // Update intention count
        totalCompletedIntentions = completedSessions.flatMap(\.tileTexts).count
        let intendedTiles = completedSessions.count * 2
        /// Update average completion rate
        averageCompletionRate = intendedTiles == 0 ? 1.0 : Double(totalCompletedIntentions) / Double(intendedTiles)
        
        /// Update recalibration counts - counts and “last choice” are always correct after app relaunch
        var newCounts: [RecalibrationMode: Int] = [:]
        var last: RecalibrationMode?
        for sesh in completedSessions {
            if let t = sesh.recalibration {
                newCounts[t, default: 0] += 1
                last = t
            }
        }
        recalibrationCounts = newCounts
        lastRecalibrationChoice = last
        
        updateRunStreak()
    }
    
    private func updateRunStreak() {
        let calendar = Calendar.current
        let daysWithSessions = Set(completedSessions.map {
            calendar.startOfDay(for: $0.date)
        })
        let sortedDays = daysWithSessions.sorted(by: >) // descending: [today, yesterday, ...]
        
        // If empty, no streak, otherwise start/continue Current Streak
        guard !sortedDays.isEmpty else {
            streak = 0
            longestStreak = 0
//            tilesCompletedThisWeek = 0
            return
            }
        
        // Run streak (most recent backward)
        var maxStreak = 1
        var currentStreak = 1
        var isTrackingCurrent = true
        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i], to: sortedDays[i - 1]).day ?? 0
            if diff == 1 {
                currentStreak += 1
                if isTrackingCurrent { streak = currentStreak }
                maxStreak = max(maxStreak, currentStreak)
            } else {
                isTrackingCurrent = false
                currentStreak = 1
            }
        }
        // If all dates are consecutive, streak isn't updated in the loop
        if isTrackingCurrent { streak = currentStreak }
        longestStreak = maxStreak
    }
    
    // MARK: Helpers + Throwing Core
    
    /// Throwing core (async throws): use when the caller wants to decide how to handle the error
    
    func logSessionThrowing( _ s: CompletedSession) async throws {
        completedSessions.append(s)
        recalculateStats()
        try await persistence.write(completedSessions, to: storageKey)
    }
    
    // Background
    func autosaveStats() {
        //            Task {
        //                do { try await persistence.saveHistory(self, to: "statsData") }
        //                catch {
        //                    debugPrint("[StatsVM.autosaveStats] error:", error)
        //                    self.lastError = error
        //                }
    }
    
    var totalRecalibrations: Int {
        recalibrationCounts.values.reduce(0, +)
    }
}

// MARK: Supporting Types -
// Keeps CompletedSession simple and fully Codable for PersistenceActor
struct CompletedSession: Codable {
    let date: Date
    let tileTexts: [String]
    let recalibration: RecalibrationMode?
}
