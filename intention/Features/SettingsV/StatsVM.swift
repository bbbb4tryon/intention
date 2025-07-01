//
//  StatsVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/30/25.
//

import Foundation
import SwiftUI

final class StatsVM: ObservableObject {
    @Published private(set) var averageCompletionRate: Double = 1.0
    @Published private(set) var totalCompletedIntentions: Int = 0
    @Published private(set) var recalibrationCounts: [RecalibrationType: Int] = [:] // what?
    @Published private(set) var runStreakDays: Int = 0
    
    private var completedSessions: [CompletedSession] = []
    
    func logSession(_ session: CompletedSession) {
        completedSessions.append(session)
        
        // Update intention count
        totalCompletedIntentions += session.tileTexts.count
        
        // Update recalibration count
        if let type = session.recalibration {   // what?
            recalibrationCounts[type, default: 0] += 1
        }
        
        // Update average completion rate
        let totalTiles = completedSessions.flatMap(\.tileTexts).count
        let intendedTiles = completedSessions.count * 2 // two tiles expected
        averageCompletionRate = Double(totalTiles) / Double(intendedTiles)
        
        // Update run streak
        updateRunStreak()
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
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay )!  //came prefilled? what?
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
