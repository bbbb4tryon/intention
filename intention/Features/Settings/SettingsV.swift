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
    @EnvironmentObject var membershipVM: MembershipVM
    @ObservedObject var viewModel: StatsVM
    
    @State private var userID: String = ""      /// aka deviceID
    
    var body: some View {
        
        let palette = theme.palette(for: .settings)
       
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    theme.styledText("Membership", as: .section, in: .settings)
                    HStack {
                        Text(membershipVM.isMember ? "Status: Active" : "Status: Not Active")
                            .foregroundStyle(membershipVM.isMember ? .green : .secondary)
                        Spacer()
                        Button("Open") { }
                    }
                    Link("Manage Subscription",
                         destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                        .foregroundStyle(.secondary)
                }
                

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
                        theme.styledText("Device ID", as: .body, in: .settings)
                        Text("Your user id: \(userID)")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
//                                    Toggle("Haptics Only", isOn: $viewModel.hapticsOnly)
//                                    Toggle("Sound Enabled", isOn: $viewModel.soundEnabled)
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
                        StatBlock(icon: "list.bullet", value: "\(viewModel.totalCompletedIntentions)", caption: "Total Intentions", palette: palette)
                        StatBlock(icon: "rosette", value: "Max Run of  \(viewModel.maxRunStreakDays) Days", caption: "Brag Stat: Longest Streak", palette: palette)
                    }
                    
                    HStack(spacing: 24){
                        StatBlock(icon: "leaf.fill", value: "\(viewModel.recalibrationCounts[.breathing, default: 0])", caption: "Breathing Sessions Completed", palette: palette)
                        StatBlock(icon: "figure.walk", value: "\(viewModel.recalibrationCounts[.balancing, default: 0])", caption: "balancing Sessions Completed", palette: palette)
                    }
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
                .foregroundStyle(palette.accent.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
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
