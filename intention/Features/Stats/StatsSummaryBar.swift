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
    
    /// Theme Hooks
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }

    var body: some View {
        HStack(spacing: 12) {
            StatPill(icon: "flame",
                      value: "\(vm.streak)",
                      caption: "Your Streak",
                      screen: .settings
            )
            .frame(maxWidth: .infinity)         // Not a child -> parent problem: makes equal columns

            StatPill(icon: "checkmark",
                     value: PercentString.whole(vm.averageCompletionRate), // FIXME: value: vm.avgCompletionString, label: "Avg.")
                      caption: "Completion",
                      screen: .settings
            )
            .frame(maxWidth: .infinity)         // Not a child -> parent problem: makes equal columns

            StatPill(icon: (vm.lastRecalibrationChoice?.iconName ?? "arrow.triangle.2.circlepath"),
                     value: "\(vm.totalRecalibrations)",
                     caption: "Recalibrations",
                     screen: .settings
            )
            .frame(maxWidth: .infinity)         // Not a child -> parent problem: makes equal columns
        }
    }
}
