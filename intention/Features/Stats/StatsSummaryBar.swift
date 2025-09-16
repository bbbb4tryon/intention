//
//  StatsSummaryBar.swift
//  intention
//
//  Created by Benjamin Tryon on 7/23/25.
//

import SwiftUI

struct StatsSummaryBar: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vm: StatsVM

    var body: some View {
        HStack(spacing: 12) {
            StatPill(icon: "flame",
                      value: "\(vm.streak)",
                      caption: "Streak",
                      screen: .settings)

            StatPill(icon: "checkmark",
                      value: String(format: "%.0f%%", vm.averageCompletionRate * 100), // FIXME: value: vm.avgCompletionString, label: "Avg.")
                      caption: "Avg. completion",
                      screen: .settings)

            if let last = vm.lastRecalibrationChoice {
                StatPill(icon: last.iconName,
                          value: last.label,
                          caption: "", // no caption for this one
                          screen: .settings)
            }
        }
    }
}
