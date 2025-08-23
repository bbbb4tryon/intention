//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
import UserNotifications

// configuration, toggles, preferences aka StatsSummaryView

struct SettingsV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var prefs: AppPreferencesVM
    @EnvironmentObject var membershipVM: MembershipVM
    @ObservedObject var viewModel: StatsVM
    
    @State private var userID: String = ""      /// aka deviceID
    
    var body: some View {
        
        let palette = theme.palette(for: .settings)
       
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    theme.styledText("Membership", as: .section, in: .settings)
                        .friendlyHelper()
                    
                    HStack {
                        Text(membershipVM.isMember ? "Status: Active" : "Status: Not Active")
                            .foregroundStyle(membershipVM.isMember ? .green : .secondary)
                        Spacer()
                        Button("Open") { }
                    }
                    /// Instead of Link()
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        Link(destination: url) {
                            theme.styledText("Manage Subscription", as: .secondary, in: .settings)
                        }
                    }
                }
                

                // Preferences Section
                VStack(alignment: .leading, spacing: 12) {
                    
                    theme.styledText("Preferences", as: .section, in: .settings)
                        .friendlyHelper()
                    
                    Toggle(isOn: .constant(false)) {
                        theme.styledText("Dark Mode", as: .body, in: .settings)
                    }
                    .friendlyAnimatedHelper("DarkMode-\(false)")
                    
                    
                    Toggle(isOn: .constant(true)) {
                        theme.styledText("Enable Notification", as: .body, in: .settings)
                    }
                    
                    Toggle(isOn: .constant(false)) {
                        VStack(alignment: .leading, spacing: 2) {
                            theme.styledText("Device ID", as: .body, in: .settings)
                            theme.styledText("Your user id: \(userID)", as: .caption, in: .settings)
                                .foregroundStyle(theme.palette(for: .settings).textSecondary)
                            theme.styledText("Sound Off", as: .caption, in: .settings)
                                .foregroundStyle(theme.palette(for: .settings).textSecondary)
                        }
                        
                        Toggle(isOn: $prefs.hapticsOnly) {
                            VStack(alignment: .leading, spacing: 2){
                                theme.styledText("Haptics Only", as: .body, in: .settings)
                                theme.styledText("Using *vibration* cues only. No sounds or alerts", as: .caption, in: .settings)
                                    .foregroundStyle(theme.palette(for: .settings).textSecondary)
                            }
                        }
                        .friendlyAnimatedHelper("hapticsOnly-\(prefs.hapticsOnly ? "on" : "off")")
                    }
                }
                
                // Color Theme Picker
                VStack(alignment: .leading, spacing: 12) {
                    theme.styledText("App Color Theme", as: .section, in: .settings)
                        .friendlyHelper()
                    
                    Picker("Color Theme", selection: $theme.colorTheme) {
                        ForEach(AppColorTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .tint(palette.accent)           /// Explicitly override for visibility
                }
                
                // Font Theme Picker
                VStack(alignment: .leading, spacing: 12) {
                    theme.styledText("Font Style", as: .section, in: .settings)
                        .friendlyHelper()
                    
                    Picker("Font Choice", selection: $theme.fontTheme) {
                        ForEach(AppFontTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .friendlyAnimatedHelper(theme.fontTheme.rawValue)
//                    .tint(palette.accent)
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    theme.styledText("Your Progress", as: .section, in: .settings)
                        .friendlyHelper()
                    
                    HStack(spacing: 20) {
                        StatBlock(icon: "list.bullet",
                            value: "\(viewModel.totalCompletedIntentions)",
                            caption: "Total Intentions",
                            palette: palette
                        )
                        StatBlock(icon: "rosette",
                            value: "Longest Run: \(viewModel.maxRunStreakDays) Days",
                            caption: "Brag Stat: Streak",
                            palette: palette)
                    }
                    .friendlyAnimatedHelper("stats-\(viewModel.totalCompletedIntentions)-\(viewModel.maxRunStreakDays)")
                    
                    HStack(spacing: 20){
                        StatBlock(icon: "leaf.fill",
                            value: "\(viewModel.recalibrationCounts[.breathing, default: 0])",
                            caption: "Breathing Sessions Completed",
                            palette: palette
                        )
                        StatBlock(
                            icon: "figure.walk",
                            value: "\(viewModel.recalibrationCounts[.balancing, default: 0])",
                            caption: "Balancing Sessions Completed",
                            palette: palette
                        )
                    }
                    .friendlyAnimatedHelper("recal-\(viewModel.recalibrationCounts[ .breathing, default: 0])-\(viewModel.recalibrationCounts[ .balancing, default: 0])")
                }
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
        .background(palette.background.ignoresSafeArea())
        .tint(palette.accent)
        .task {
        /// Read it directly from your keychain on-demand - actor requires only await, not async here
            userID = await KeychainHelper.shared.getUserIdentifier()
        }
    }


    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            print("Permission granted: \(granted)")
        }
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
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(palette.surface)            /// Subtle cards and consistent caption style
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}


#Preview("Stats & Settings") {
    MainActor.assumeIsolated {
        let stats = PreviewMocks.stats
        stats.logSession(CompletedSession(date: .now, tileTexts: ["By Example", "Analysis checklist"], recalibration: .breathing))

        return PreviewWrapper {
            SettingsV(viewModel: PreviewMocks.stats)
                .previewTheme()
        }
    }
}
