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
    @Published private(set) var runStreakDays: Int = 0
    @Published var shouldPromptForMembership: Bool = false  // is good flag
    private let membershipThreshold = 2
    
    private var completedSessions: [CompletedSession] = []
    
    func logSession(_ session: CompletedSession) {
        completedSessions.append(session)
        
        /// Update intention count
        totalCompletedIntentions += session.tileTexts.count
        
        /// if user did recalibrate (picked breathe or balance), type will be non-nil, and count incremented
        if let type = session.recalibration {   // what?
            recalibrationCounts[type, default: 0] += 1
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
        let daysWithSessions = Set(completedSessions.map { calendar.startOfDay(for: $0.date)    })
        let sortedDays = daysWithSessions.sorted(by: >)
        
        var streak = 0
        var currentDay = calendar.startOfDay(for: Date())
        
        for day in sortedDays {
            if day == currentDay {
                streak += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay )!  // Safe unwrap: ! is safe here bc byAdding .day will not return nil, will never fail
            } else {
                break
            }
        }
        runStreakDays = streak
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
    case breathe, balance
}
