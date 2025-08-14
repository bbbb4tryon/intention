//
//  StatsVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/30/25.
//

import Foundation
import SwiftUI

enum StatsVMError: Error, Equatable {
    case didNotLoadFromPersistence
}

@MainActor
final class StatsVM: ObservableObject {
    @Published private(set) var averageCompletionRate: Double = 1.0
    @Published private(set) var totalCompletedIntentions: Int = 0
    @Published private(set) var recalibrationCounts: [RecalibrationType: Int] = [:] // what?
    @Published private(set) var lastRecalibrationChoice: RecalibrationType? = nil
    @Published private(set) var runStreakDays: Int = 0
    @Published private(set) var maxRunStreakDays: Int = 0
    @Published var shouldPromptForMembership: Bool = false  // is good flag
    @Published var lastError: Error?
    
    private let persistence: Persistence
    private let storageKey = "completedSessions"
    private let membershipThreshold = 2
    private var completedSessions: [CompletedSession] = []
    
    weak var membershipVM: MembershipVM?
    
    init(persistence: Persistence){
        self.persistence = persistence
        Task {  await loadSessions()    }
    }
    
    func logSession(_ session: CompletedSession) {
        completedSessions.append(session)
        // Update intention count
        totalCompletedIntentions = completedSessions.flatMap(\.tileTexts).count
        membershipVM?.triggerPromptifNeeded(afterSessions: completedSessions.count)
        
        /// if user did recalibrate (picked breathing or balancing), type will be non-nil, and count incremented
        if let type = session.recalibration {
            recalibrationCounts[type, default: 0] += 1
            lastRecalibrationChoice = type
        }
        
        recalculateStats()
        
        /// Updates to trigger memberhship prompt ($0.99 then $5.99 for 3 months?)
        /// Keeps onboarding friction at zero: the user never types anything.
        if completedSessions.count == membershipThreshold {
            shouldPromptForMembership = true    // Observe in the RootView and present as alert/sheet
        }
        
        Task {
            do {
                try await persistence.saveHistory(completedSessions, to: storageKey)
            } catch {
                debugPrint("[StatsVM.logSession persistence.saveHistory] error:", error)
                await MainActor.run { self.lastError = error }
            }
        }
    }
    
    private func loadSessions() async {
        do {
            if let loaded: [CompletedSession] = try await persistence.loadHistory([CompletedSession].self, from: storageKey) {
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
        
        let totalTiles = totalCompletedIntentions
        let intendedTiles = completedSessions.count * 2
        /// Update average completion rate
        averageCompletionRate = intendedTiles == 0 ? 1.0 : Double(totalTiles) / Double(intendedTiles)
        
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
            runStreakDays = 0
            maxRunStreakDays = 0
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
                if isTrackingCurrent { runStreakDays = currentStreak }
                maxStreak = max(maxStreak, currentStreak)
            } else {
                isTrackingCurrent = false
                currentStreak = 1
            }
        }
        // If all dates are consecutive, runStreakDays isn't updated in the loop
        if isTrackingCurrent { runStreakDays = currentStreak }
        maxRunStreakDays = maxStreak
    }
    
    
    // MARK: Helpers + Throwing Core
    
    ///Throwing core (async throws): use when the caller wants to decide how to handle the error
    
    func logSessionThrowing( _ s: CompletedSession) async throws {
        completedSessions.append(s)
        recalculateStats()
        try await persistence.saveHistory(completedSessions, to: storageKey)
    }
}

// MARK: Supporting Types -
// Keeps CompletedSession simple and fully Codable for PersistenceActor
struct CompletedSession: Codable {
    let date: Date
    let tileTexts: [String]
    let recalibration: RecalibrationType?
}

