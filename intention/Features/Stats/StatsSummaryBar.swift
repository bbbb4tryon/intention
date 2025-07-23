//
//  StatsSummaryBar.swift
//  intention
//
//  Created by Benjamin Tryon on 7/23/25.
//

import SwiftUI

struct StatsSummaryBar: View {
    @EnvironmentObject var statsVM: StatsVM
    let palette: ScreenStylePalette
    
    var body: some View {
        HStack(spacing: 16) {
            StatBlock(icon: "flame.fill", value: "\(statsVM.runStreakDays) Days", caption: "Streak", palette: palette)
            StatBlock(icon: "checkmark.circle.fill", value: String(format: "%.0f%%", statsVM.averageCompletionRate * 100), caption: "Completion Rate", palette: palette)
            if let last = statsVM.lastRecalibrationChoice {
                StatBlock(icon: last.iconName, value: last.label, caption: "Last Reset", palette: palette)
            }
        }
        .padding(.horizontal)
    }
}


private struct StatBlock: View {
    let icon: String
    let value: String
    let caption: String
    let palette: ScreenStylePalette
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(palette.accent)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(palette.text)
            Text(caption)
                .font(.caption)
                .foregroundStyle(palette.accent.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}
