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
    @EnvironmentObject var memVM: MembershipVM
    @ObservedObject var statsVM: StatsVM
    @AppStorage(DebugKeys.forceLegalNextLaunch) private var debugShowLegalNextLaunch = false
    
    @State private var userID: String = ""      /// aka deviceID
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showMedical = false
    
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        ScrollView {
            Page(top: 4, alignment: .center) {
        #if DEBUG
        Section("Developer") {
            Button("Reset Legal Gate Now") {
                LegalConsent.clearForDebug() // your helper that clears acceptance
            }
            Toggle("Show Legal on Next Launch", isOn: $debugShowLegalNextLaunch)
        }
        #endif


                Card {
                    VStack(alignment: .leading, spacing: 8){
                        T("Membership", .section)
                        //                        .friendlyHelper()
                        (memVM.isMember
                         ? T("Status: Active", .secondary) : T("Status: Not Active", .secondary)
                        )
                        .foregroundStyle(memVM.isMember ? .green : .secondary)
                        
                        T("Your user ID/device ID: \(userID)", .caption)
                            .foregroundStyle(p.textSecondary)
                        HStack(spacing: 12){
                            Button (action: {
                                /// Instead of Link()
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                T("Manage Subscription", .header)
                            }
                            .primaryActionStyle(screen: .settings)
                            .tint(p.accent)
                        }
                    }
                }
                
                /// Stats
                Card {
                    HStack(spacing: 20) {
                        StatPill(icon: "list.bullet",
                                  value: "\(statsVM.totalCompletedIntentions)",
                                  caption: "Accomplished",
                                  screen: .settings)
                        
                        StatPill(icon: "rosette",
                                  value: "\(statsVM.longestStreak)",
                                  caption: "Streak",
                                  screen: .settings)
                    }
                    Divider()
                    HStack(spacing: 20) {
                        StatPill(icon: "leaf.fill",
                                  value: "\(statsVM.recalibrationCounts[.breathing,  default: 0])",
                                  caption: "Breathing",
                                  screen: .settings)
                        StatPill(icon: "figure.walk",
                                  value: "\(statsVM.recalibrationCounts[.balancing,  default: 0])",
                                  caption: "Balancing",
                                  screen: .settings)
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
                        
                        // Color Theme Picker
                        Picker(selection: $theme.colorTheme) {
                            ForEach(AppColorTheme.allCases, id: \.self) { option in Text(option.displayName).tag(option) }
                        } label: {
                            T("Color", .label)          // themed label
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(p.accent)                 // segment highlight color
                        
                        // Font Theme Picker
                        Picker(selection: $theme.fontTheme) {
                            ForEach(AppFontTheme.allCases, id: \.self) { option in Text(option.displayName).tag(option) }
                        } label: {
                            T("Font", .section)     // themed label
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(p.accent)
                        .friendlyAnimatedHelper(theme.fontTheme.rawValue)
                    }
                }
                
                /// Legal (reprise)
                Card {
                    VStack(alignment: .leading, spacing: 8){
                        
                        SettingsLegalSection(
                          onShowTerms:   { showTerms = true },
                          onShowPrivacy: { showPrivacy = true },
                          onShowMedical: { showMedical = true }
                        )
                        .sheet(isPresented: $showTerms) {
                          NavigationStack { LegalDocV(title: "Terms of Use",
                            markdown: MarkdownLoader.load(named: LegalConfig.termsFile)) }
                        }
                        .sheet(isPresented: $showPrivacy) {
                          NavigationStack { LegalDocV(title: "Privacy Policy",
                            markdown: MarkdownLoader.load(named: LegalConfig.privacyFile)) }
                        }
                        .sheet(isPresented: $showMedical) {
                          NavigationStack { LegalDocV(title: "Wellness Disclaimer",
                            markdown: MarkdownLoader.load(named: LegalConfig.medicalFile)) }
                        }
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

#if DEBUG
#Preview("Stats & Settings") {
    MainActor.assumeIsolated {
        let stats = PreviewMocks.stats
        stats.logSession(CompletedSession(date: .now, tileTexts: ["By Example", "Analysis checklist"], recalibration: .breathing))

        return PreviewWrapper {
            SettingsV(statsVM: PreviewMocks.stats)
                .previewTheme()
        }
    }
}
#endif
