//
//  StatsVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/30/25.
//

import Foundation
import SwiftUI
import Algorithms

final class StatsVM: ObservableObject {
    @Published private(set) var averageCompletionRate: Double = 1.0
    @Published private(set) var totalCompletedIntentions: Int = 0
    @Published private(set) var recalibrationCounts: [RecalibrationType: Int] = [:] // what?
    @Published private(set) var lastRecalibrationChoice: RecalibrationType? = nil
    @Published private(set) var runStreakDays: Int = 0
    @Published private(set) var maxRunStreakDays: Int = 0
    @Published var shouldPromptForMembership: Bool = false  // is good flag
    private let membershipThreshold = 2
    
    private var completedSessions: [CompletedSession] = []
    
    func logSession(_ session: CompletedSession) {
        completedSessions.append(session)
        
        /// Update intention count
        totalCompletedIntentions += session.tileTexts.count
        
        /// if user did recalibrate (picked breathing or balancing), type will be non-nil, and count incremented
        if let type = session.recalibration {   // what?
            recalibrationCounts[type, default: 0] += 1
            lastRecalibrationChoice = type
        }
        
        /// Update average completion rate
        let totalTiles = completedSessions.flatMap(\.tileTexts).count
        let intendedTiles = completedSessions.count * 2 // two tiles expected
        averageCompletionRate = Double(totalTiles) / Double(intendedTiles)
        
        /// Update run streak
        updateRunStreak()
        
        /// Updates to trigger memberhship prompt ($0.99 then $5.99 for 3 months?)
        /// Keeps onboarding friction at zero: the user never types anything.
        if completedSessions.count == membershipThreshold {
            shouldPromptForMembership = true    // Observe in the RootView and present as alert/sheet
        }
    }
    
    private func updateRunStreak() {
        let calendar = Calendar.current
        let daysWithSessions = Set(completedSessions.map {
            calendar.startOfDay(for: $0.date)
        })
        let sortedDays = daysWithSessions.sorted(by: >) // descending: [today, yesterday, ...]
        
        // If empty, no streak, otherwise start/continue Current Streak
        guard let today = sortedDays.first else {
            runStreakDays = 0
            maxRunStreakDays = 0
            tilesCompletedThisWeek = 0
            return
            }
        
        // adjacentPairs walks day-by-day backwards
        /*
         if `sortedDays` contains [Jan 22, Jan 21, Jan 20, Jan 17] -- days used, gap days not included (19th and 18th)
         `.adjacentPairs()` gives [(22,21),(21,20),(20,17)]
         `.prefix { daysDiff == 1 }` keeps (22,21),(21,20)
         that is the current day and 2 consecutive days (3 links of (consecutivePairs.count + 1),(22,21),(21,20))
         */
        let currentStreakPairs = sortedDays
            .adjacentPairs()
            .prefix { lhs, rhs in
                calendar.dateComponents([.day], from: rhs, to: lhs).day == 1
            }
        // Add 1 to include the first day
        runStreakDays = currentStreakPairs.count + 1
        
        // Maximum Streak - scan entired sorted list for all consecutive segments
        //  each element in `allStreaks` is a chain of consecutive days [22,21,20]
        //  .split(where:) segments the array at any gaps
        let allStreaks = sortedDays
            .adjacentPairs()
            .split { lhs, rhs in
                calendar.dateComponents([.day], from: rhs, to: lhs).day != 1
            }
        maxRunStreakDays = allStreaks
            .map { $0.count + 1 }   // .count + 1 because .adjacentPairs() drops 1 value
            .max() ?? 1             // finds longest segment
    }
}

// MARK: Supporting Types -
struct CompletedSession {
    let date: Date
    let tileTexts: [String]
    let recalibration: RecalibrationType?
}

// FIXME: is this already created?
enum RecalibrationType: String, CaseIterable, Hashable {
    case breathing, balancing
}
