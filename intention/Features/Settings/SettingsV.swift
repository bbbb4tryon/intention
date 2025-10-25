//
//  SettingsV.swift
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
    @EnvironmentObject var focusVM: FocusSessionVM
    @ObservedObject var statsVM: StatsVM
    @AppStorage(DebugKeys.forceLegalNextLaunch) private var debugShowLegalNextLaunch = false
    
    @State private var userID: String = ""      /// aka deviceID
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showMedical = false
    @State private var isBusy = false
    
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    // --- Local Color Definitions Settings ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        ScrollView {
            Page(top: 4, alignment: .center) {
                T("Settings", .header)
                    .padding(.bottom, 4)
                
#if DEBUG
                // DisclosureGroup<Label, Content>(label: Label, @ViewBuilder content: () -> Content)
                // where the label is the first (non-closure) argument, and the content is the trailing closure
                // use the implicit first and second trailing closures:
                // The Label argument (mandatory for this initializer with DisclosureGroup)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 6) {
                        Button("Clear: Debug") {
                            UserDefaults.standard.removeObject(forKey: "debug.chunkSeconds")
                        }
                        Button("Reset: Legal Gate") { LegalConsent.clearForDebug() }
                            .controlSize(.large)
                        
                        Toggle("Show Legal on Next Launch", isOn: $debugShowLegalNextLaunch)
                        
                        Button("Show Organizer")    { NotificationCenter.default.post(name: .devOpenOrganizerOverlay, object: nil) }
                        Button("Show Recalibration"){ NotificationCenter.default.post(name: .devOpenRecalibration,      object: nil) }
                        Button("Show Membership")   { NotificationCenter.default.post(name: .devOpenMembership,         object: nil) }
                        Button("Show ErrorOverlay") { NotificationCenter.default.post(name: .devOpenErrorOverlay,       object: nil) }
                        
                        Button("Reset Session")     { Task { await focusVM.resetSessionStateForNewStart() } }
                        
                        Picker("Timer debug", selection: Binding( get: { UserDefaults.standard.integer(forKey: "debug.chunkSeconds") }, set: { UserDefaults.standard.set($0, forKey: "debug.chunkSeconds") } )) { Text("10s").tag(10); Text("30s").tag(30); Text("60s").tag(60); Text("OFF (20m)").tag(0) // 0 disables override
                        }}.controlSize(.small) .font(.footnote) .buttonStyle(.bordered)
                } label: {
                    Label("Dev", systemImage: "wrench")         // Dumb words, but this is the CONTENT closure
                }
#endif
                
                // MARK: Support
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Support", .section)
                        NavigationLink {
                            FeedbackV()
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                T("Send Feedback", .action)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderless)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
                
                // MARK: Membership
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Membership", .section)
                        //                        .friendlyHelper()
                        (memVM.isMember
                         ? T("Status: Active", .secondary).bold() : T("Status: Not Active", .secondary).bold()
                        )
                        .foregroundStyle(memVM.isMember ? .green : .secondary)
                        
                        T("Your user ID/device ID: \(userID)", .caption)
                            .foregroundStyle(textSecondary)
                        HStack(spacing: 12) {
                            Button(action: {
                                /// Instead of Link()
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                T("Manage Subscription", .action)
                            }
                            .primaryActionStyle(screen: .settings)
                            .frame(maxWidth: .infinity)
                            .tint(p.accent)
                        }
                    }
                }
                
                // MARK: Stats
                Card {
                    Grid(horizontalSpacing: 12, verticalSpacing: 12){
                        GridRow {
                            StatPill(icon: "list.bullet",
                                     value: "\(statsVM.totalCompletedIntentions)",
                                     caption: "Accomplished",
                                     screen: .settings)
                            
                            StatPill(icon: "rosette",
                                     value: "\(statsVM.longestStreak)",
                                     caption: "Streak",
                                     screen: .settings)
                            //                        }
                            //                        GridRow {
                            StatPill(icon: "leaf.fill",
                                     value: "\(statsVM.recalibrationCounts[.breathing, default: 0])",
                                     caption: "Breathing",
                                     screen: .settings)
                            StatPill(icon: "figure.walk",
                                     value: "\(statsVM.recalibrationCounts[.balancing, default: 0])",
                                     caption: "Balancing",
                                     screen: .settings)
                            
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Divider()
                
                // MARK: Preferences
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Preferences", .section)
                        Toggle(isOn: .constant(true)) { T("Enable Notification", .caption) }
                        Toggle(isOn: $prefs.hapticsOnly) { T("Haptics Only: Vibration cues only", .caption)
                            .foregroundStyle(textSecondary) }
                        Toggle(isOn: .constant(false)) { T("Sound Off", .caption) }
                            .controlSize(.small)        /// Toggle size
                            .toggleStyle(SwitchToggleStyle(tint: p.accent))
                    }
                    .friendlyAnimatedHelper("hapticsOnly-\(prefs.hapticsOnly ? "on" : "off")")
                }
                
                // MARK: Customization
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Personalization", .section)
                        
                        // Color Theme Picker
                        Picker(selection: $theme.colorTheme) {
                            ForEach(AppColorTheme.publicCases, id: \.self) { option in Text(option.displayName).tag(option) }
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
                
                // MARK: Legal (reprise)
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        SettingsLegalSection(
                            onShowTerms: { showTerms = true },
                            onShowPrivacy: { showPrivacy = true },
                            onShowMedical: { showMedical = true }
                        )
                        .sheet(isPresented: $showTerms) {
                            NavigationStack {
                                LegalDocV(
                                    title: "Terms of Use",
                                    markdown: MarkdownLoader
                                        .load(named: LegalConfig.termsFile)
                                )
                            }
                        }
                        .sheet(isPresented: $showPrivacy) {
                            NavigationStack {
                                LegalDocV(
                                    title: "Privacy Policy",
                                    markdown: MarkdownLoader
                                        .load(named: LegalConfig.privacyFile)
                                )
                            }
                        }
                        .sheet(isPresented: $showMedical) {
                            NavigationStack {
                                LegalDocV(
                                    title: "Wellness Disclaimer",
                                    markdown: MarkdownLoader
                                        .load(named: LegalConfig.medicalFile)
                                )
                            }
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
