//
//  StatsSummaryBar.swift
//  intention
//
//  Created by Benjamin Tryon on 7/23/25.
//

import SwiftUI

struct StatsSummaryBar: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var statsVM: StatsVM
   

    var body: some View {
        HStack(spacing: 12) {
            StatBlock(icon: "flame.fill",
                      value: "\(statsVM.runStreakDays)",
                      caption: "Streak",
                      screen: .settings)

            StatBlock(icon: "checkmark.circle.fill",
                      value: String(format: "%.0f%%", statsVM.averageCompletionRate * 100),
                      caption: "Avg. completion",
                      screen: .settings)

            if let last = statsVM.lastRecalibrationChoice {
                StatBlock(icon: last.iconName,
                          value: last.label,
                          caption: "", // no caption for this one
                          screen: .settings)
            }
        }
    }
}
