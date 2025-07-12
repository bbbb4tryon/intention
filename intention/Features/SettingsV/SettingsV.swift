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
    @EnvironmentObject var userService: UserService
    @ObservedObject var viewModel: StatsVM
    
    var body: some View {
        
        let palette = theme.palette(for: .settings)
       
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
                    Toggle(isOn: .constant(false)) {
                        theme.styledText("User ID", as: .body, in: .settings)
                        Text("Your user id: \(userService)")
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
                    .tint(palette.accent)   // Explicitly override for visibility
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
                    .tint(palette.accent)
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    theme.styledText("Your Progress", as: .section, in: .settings)
                    
                    HStack(spacing: 24) {
                        StatBlock(icon: "checkmark.circle.fill", value: String(format: "%.0f%%", viewModel.averageCompletionRate * 100), caption: "Avg. Completion Rate", palette: palette)
                        StatBlock(icon: "list.bullet", value: "\(viewModel.totalCompletedIntentions)", caption: "Total Intentions", palette: palette)
                    }
                    
                    HStack(spacing: 24){
                        StatBlock(icon: "leaf.fill", value: "\(viewModel.recalibrationCounts[.breathe, default: 0])", caption: "Breathe Sessions", palette: palette)
                        StatBlock(icon: "figure.walk", value: "\(viewModel.recalibrationCounts[.balance, default: 0])", caption: "Balance Sessions", palette: palette)
                    }
                    
                    HStack(spacing: 24){
                        StatBlock(icon: "flame.fill", value: "\(viewModel.runStreakDays) Days", caption: "Run Streak", palette: palette)
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

#Preview {
    let stats = StatsVM()
       let sampleSession = CompletedSession(date: Date(), tileTexts: ["Write Chapter", "Edit Draft"], recalibration: .breathe)
       stats.logSession(sampleSession)
       stats.logSession(sampleSession)
       stats.logSession(CompletedSession(date: Date().addingTimeInterval(-86400), tileTexts: ["Read Notes", "Outline Next Part"], recalibration: .balance))

       let userService = UserService()
       let theme = ThemeManager()

       return SettingsV(viewModel: stats)
           .environmentObject(userService)
           .environmentObject(theme)
           .previewTheme()
}
/*
 Background: .intTan

 Title text: .intBrown

 Toggle labels: .intGreen or .intMoss

 Destructive toggle: maybe .intBrown.opacity(0.7) if needed


 */
