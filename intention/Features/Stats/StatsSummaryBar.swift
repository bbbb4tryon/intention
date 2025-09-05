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
    let p: ScreenStylePalette
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .settings)) }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            StatBlock(icon: "flame.fill", value: "\(statsVM.runStreakDays)", caption: T("Streak" .caption), palette: p)
            StatBlock(icon: "checkmark.circle.fill", value: String(format: "%.0f%%", statsVM.averageCompletionRate * 100), caption: T("Avg. completion", .caption), palette: p)
            if let last = statsVM.lastRecalibrationChoice {
                StatBlock(icon: last.iconName, value: last.label, caption: T("", .caption), palette: p)
            }
        }
    }
}


private struct StatBlock: View {
    let icon: String
    let value: String
    let p: ScreenStylePalette
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .settings)) }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(palette.accent)
            T("\(value)")
                .bold()
                .foregroundStyle(palette.text)
            T("\(key)")
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 8)
//        .background(palette.surface)            /// Subtle cards and consistent caption style
//        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
