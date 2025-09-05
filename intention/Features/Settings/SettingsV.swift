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
    
    private var p: ThemePalette { theme.palette(for: .settings) }
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .settings)) }
    }
    
    var body: some View {
//        let p = theme.palette(for: .settings)
       
        ScrollView {
            Page(top: 4, alignment: .center) {
                Card {
                    VStack(alignment: .leading, spacing: 8){
                        T("Membership", .section)
                        //                        .friendlyHelper()
                        membershipVM.isMember ? T("Status: Active", .secondary) : T("Status: Not Active", .secondary)
                            .foregroundStyle(membershipVM.isMember ? .green : .secondary)
                        //                            .foregroundStyle(palette.textSecondary)
                        
                        T("Your user ID/device ID: \(userID)", .caption)
                            .foregroundStyle(p.textSecondary)
                        HStack(spacing: 12){
                            Button (T("Manage Subscription", .header)) {
                                /// Instead of Link()
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .primaryActionStyle(screen: .settings)
                            .tint(p.accent)
                        }
                    }
                }
                
                /// Stats
                Card {
                    VStack(alignment: .leading,spacing: 8){
                        T("Profile", .section)
                            .friendlyHelper()
                        
                        HStack(spacing: 20) {
                            StatBlock(icon: "list.bullet", value: "\(viewModel.totalCompletedIntentions)", caption: T("Accomplished", .caption), palette: p  )
                            StatBlock(icon: "rosette", value: "\(viewModel.maxRunStreakDays)", caption: T("Streak", .caption), palette: p )
                        }
                        .friendlyAnimatedHelper("stats-\(viewModel.totalCompletedIntentions)-\(viewModel.maxRunStreakDays)")
                        
                        Divider()
                        HStack(spacing: 20){
                            StatBlock(icon: "leaf.fill", value: "\(viewModel.recalibrationCounts[.breathing, default: 0])", caption: _, palette: p )
                            StatBlock(icon: "figure.walk", value: "\(viewModel.recalibrationCounts[.balancing, default: 0])", caption: _, palette: p )
                        }
                        .friendlyAnimatedHelper("recal-\(viewModel.recalibrationCounts[.breathing, default: 0])-\(viewModel.recalibrationCounts[.balancing, default: 0])")
                    }
                }
                
                Divider()
                
                /// Preferences Section
                Card {
                    VStack(alignment: .leading,spacing: 8){
                        T("Preferences", .section)
                        Toggle(isOn: .constant(true)) { T("Enable Notification", .caption) }
                        Toggle(isOn: $prefs.hapticsOnly) { T("Haptics Only: Vibration cues only", .caption)
                                .foregroundStyle(p.textSecondary) }
                        Toggle(isOn: .constant(false)) { T("Sound Off", .caption) }
                        .controlSize(.small)        /// Toggle size
                        .toggleStyle(SwitchToggleStyle(tint: p.accent))
                }
                .friendlyAnimatedHelper("hapticsOnly-\(prefs.hapticsOnly ? "on" : "off")")
            }
                
                /// Color Theme Picker
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Personalization", .section)
            
                        Picker(T("Color", .section), selection: $theme.colorTheme) {
                            ForEach(AppColorTheme.allCases, id: \.self) { theme in Text(theme.displayName).tag(theme) }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        /// Font Theme Picker
                        Picker(T("Font", .section), selection: $theme.fontTheme) {
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
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
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
