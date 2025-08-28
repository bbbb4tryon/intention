//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI
import UserNotifications

struct SettingsV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var prefs: AppPreferencesVM
    @EnvironmentObject var membershipVM: MembershipVM
    @ObservedObject var viewModel: StatsVM
    
    @State private var userID: String = ""      /// aka deviceID
    
    var body: some View {
        let palette = theme.palette(for: .settings)
       
        ScrollView {
            Page {
                Card {
                    VStack(alignment: .leading, spacing: 8){
                        theme.styledText("Membership", as: .section, in: .settings)
                        //                        .friendlyHelper()                   //FIXME: NEED THESE IN EACH?
                        theme.styledText((membershipVM.isMember ? "Status: Active" : "Status: Not Active"), as: .secondary, in: .settings)
                            .foregroundStyle(membershipVM.isMember ? .green : .secondary)
                        //                            .foregroundStyle(palette.textSecondary)
                        
                        theme.styledText("Device ID: ", as: .caption, in: .settings)
                            .foregroundStyle(palette.textSecondary)
                        theme.styledText("Your user id: \(userID)", as: .caption, in: .settings)
                            .foregroundStyle(palette.textSecondary)
                        HStack(spacing: 12){
                            Button ("Manage Subscription") {
                                /// Instead of Link()
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .primaryActionStyle(screen: .settings)
                            .tint(palette.accent)
                        }
                    }
                }
                
                /// Stats
                Card {
                    VStack(alignment: .leading,spacing: 8){
                        theme.styledText("Your Progress", as: .section, in: .settings)
                            .friendlyHelper()
                        
                        HStack(spacing: 20) {
                            StatBlock(icon: "list.bullet", value: "\(viewModel.totalCompletedIntentions)", caption: "Total Intentions", palette: palette  )
                            StatBlock(icon: "rosette", value: "Longest Run: \(viewModel.maxRunStreakDays) Days", caption: "Brag Stat: Streak", palette: palette )
                        }
                        .friendlyAnimatedHelper("stats-\(viewModel.totalCompletedIntentions)-\(viewModel.maxRunStreakDays)")
                        
                        Divider()
                        HStack(spacing: 20){
                            StatBlock(icon: "leaf.fill", value: "\(viewModel.recalibrationCounts[.breathing, default: 0])", caption: "Breathing Sessions Completed", palette: palette )
                            StatBlock(icon: "figure.walk", value: "\(viewModel.recalibrationCounts[.balancing, default: 0])", caption: "Balancing Sessions Completed", palette: palette )
                        }
                        .friendlyAnimatedHelper("recal-\(viewModel.recalibrationCounts[ .breathing, default: 0])-\(viewModel.recalibrationCounts[ .balancing, default: 0])")
                    }
                }
                
                Divider()
                
                /// Preferences Section
                Card {
                    VStack(alignment: .leading,spacing: 8){
                    theme.styledText("Preferences", as: .section, in: .settings)
                    Toggle(isOn: .constant(true))
                    { theme.styledText("Enable Notification", as: .caption, in: .settings) }
                    Toggle(isOn: .constant(false))
                    { theme.styledText("Sound Off", as: .caption, in: .settings) }
                    Toggle(isOn: $prefs.hapticsOnly)
                        { theme.styledText("Haptics Only: Vibration cues only", as: .caption, in: .settings)
                                .foregroundStyle(palette.textSecondary)
                        }
                        .controlSize(.small)        /// Toggle size
                        .toggleStyle(SwitchToggleStyle(tint: palette.accent))
                }
                .friendlyAnimatedHelper("hapticsOnly-\(prefs.hapticsOnly ? "on" : "off")")
            }
                
                /// Color Theme Picker
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        theme.styledText("Personalization", as: .section, in: .settings)
                        theme.styledText("App Color Theme", as: .secondary, in: .settings)
                        Picker("Color Theme", selection: $theme.colorTheme) {
                            ForEach(AppColorTheme.allCases, id: \.self) { theme in Text(theme.displayName).tag(theme) }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        /// Font Theme Picker
                        theme.styledText("Font Style", as: .section, in: .settings)
                        Picker("Font Choice", selection: $theme.fontTheme) {
                            ForEach(AppFontTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .friendlyAnimatedHelper(theme.fontTheme.rawValue)
                        // .tint(palette.accent) /// Explicitly override for visibility //FIXME: DO THIS FOR ALL CARDS?
                    }
                }
            }
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
            Image(systemName: icon).font(.title2) .foregroundStyle(palette.accent)
            Text(value).font(.title3).bold().foregroundStyle(palette.text)
            Text(caption).font(.caption) .foregroundStyle(palette.textSecondary)
        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 8)
//        .background(palette.surface)            /// Subtle cards and consistent caption style
//        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
