//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

// configuration, toggles, preferences

struct SettingsV: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: StatsVM
    
    var body: some View {
        
        let palette = theme.palette(for: .settings)
        let fontTheme = theme.fontTheme
        
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                theme.styledText("Settings", as: .header, in: .settings)
                    .padding(.top, 12)
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 12) {
                    theme.styledText("Preferences", as: .section, in: .settings)
                    
                    Toggle(isOn: .constant(false)) {
                        theme.styledText("Dark Mode", as: .body, in: .settings)
                    }
                    
                    Toggle(isOn: .constant(true)) {
                        theme.styledText("Enable Notification", as: .body, in: .settings)
                    }
                    //                Toggle("Haptics Only", isOn: $viewModel.hapticsOnly)
                    //                Toggle("Sound Enabled", isOn: $viewModel.soundEnabled)
                }
                
                // Color Theme Picker
                VStack(alignment: .leading, spacing: 12) {
                    theme.styledText("App Color Theme", as: .section, in: .settings)
                    
                    Picker("Color Theme", selection: $theme.colorTheme) {
                        ForEach(AppColorTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Font Theme Picker
                VStack(alignment: .leading, spacing: 12) {
                    theme.styledText("Font Style", as: .section, in: .settings)
                    
                    Picker("Font Choice", selection: $theme.fontTheme) {
                        ForEach(AppFontTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    theme.styledText("Your Progress", as: .section, in: .settings)
                    
                    HStack(spacing: 24) {
                        StatBlock(icon: "checkmark.circle.fill", value: String(format: "%.0f%%", viewModel.averageCompletionRate * 100), caption: "Avg. Completion Rate")
                        StatBlock(icon: "list.bullet", value: "\(viewModel.totalCompletedIntentions)", caption: "Total Intentions")
                    }
                    
                    HStack(spacing: 24){
                        StatBlock(icon: "leaf.fill", value: "\(viewModel.recalibrationCounts[.breathe, default: 0])", caption: "Breathe Sessions")
                        StatBlock(icon: "figure.walk", value: "\(viewModel.recalibrationCounts[.balance, default: 0])", caption: "Balance Sessions")
                    }
                    
                    HStack(spacing: 24){
                        StatBlock(icon: "flame.fill", value: "\(viewModel.runStreakDays) Days", caption: "Run Streak")
                    }
                }
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
        .background(palette.background.ignoresSafeArea())
        .tint(palette.accent)
    }
}

private struct StatBlock: View {
    let icon: String
    let value: String
    let caption: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
            Text(value)
                .font(.title3)
                .bold()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
//    let stats = StatsVM()
//
//       // Mock data for preview
//       let sampleSession = CompletedSession(date: Date(), tileTexts: ["Intend A", "Intend B"], recalibration: .breathe)
//       stats.logSession(sampleSession)
//       stats.logSession(sampleSession)
//       stats.logSession(CompletedSession(date: Date().addingTimeInterval(-86400), tileTexts: ["C", "D"], recalibration: .balance))

    SettingsV(viewModel: StatsVM())
           .previewTheme()
}
/*
 Background: .intTan

 Title text: .intBrown

 Toggle labels: .intGreen or .intMoss

 Destructive toggle: maybe .intBrown.opacity(0.7) if needed


 */
