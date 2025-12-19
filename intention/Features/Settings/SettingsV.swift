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
    @State private var showSwatches = false
    
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions Settings ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        ScrollView {
            Page(top: 4, alignment: .center) {
                T("Settings", .header)
                    .padding(.bottom, 4)
                
                // MARK: Support
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Support", .section)
                        NavigationLink {
                            FeedbackV()
                        } label: {
                            HStack(spacing: 12){
                                Image(systemName: "paperplane.fill")
                                    .padding(.horizontal, 2)
                                T("Send Feedback", .action)
                                
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .primaryActionStyle(screen: .settings)
                        .frame(maxWidth: .infinity)
                        .tint(p.accent)
                        .padding(.vertical, 6)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
                
                // MARK: Membership
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        T("Membership", .section)
                        //                        .friendlyHelper()
                        HStack {
                            T(memVM.isMember ? "Status: Subscribed" : "Status: Not Subscribed", .label)
                        }
                        .foregroundStyle(memVM.isMember ? .green : .secondary)
                        HStack {
                            T("Your ID:", .caption)
                            T(userID, .caption)
                                .foregroundStyle(textSecondary)
                        }
                        HStack(spacing: 12) {
                            Button(action: {
                                /// Instead of Link()
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                T("Purchase", .action)
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
                        // NOTE: these are primary control labels; caption is too small/low-contrast
                        Toggle(isOn: .constant(true)) { T("Enable Notification", .label) }
                        Toggle(isOn: $prefs.hapticsOnly) { T("Only Vibrations", .label)
                            .foregroundStyle(textSecondary) }
                        Toggle(isOn: .constant(false)) { T("Sound Enabled", .label) }
                            .controlSize(.small)        /// Toggle size
                            .toggleStyle(SwitchToggleStyle(tint: p.accent))
                    }
                    .friendlyAnimatedHelper("hapticsOnly-\(prefs.hapticsOnly ? "on" : "off")")
                    .friendlyAnimatedHelper("soundEnabled-\(prefs.soundEnabled ? "off" : "on")")
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
                                        .load(named: LegalConfig.termsFile),
                                    palette: theme.palette(for: .settings
                                                          )
                                )
                            }
                        }
                        .sheet(isPresented: $showPrivacy) {
                            NavigationStack {
                                LegalDocV(
                                    title: "Privacy Policy",
                                    markdown: MarkdownLoader
                                        .load(named: LegalConfig.privacyFile),
                                    palette: theme.palette(for: .settings
                                                          )
                                )
                            }
                        }
                        .sheet(isPresented: $showMedical) {
                            NavigationStack {
                                LegalDocV(
                                    title: "Wellness Disclaimer",
                                    markdown: MarkdownLoader
                                        .load(named: LegalConfig.medicalFile),
                                    palette: theme.palette(for: .settings
                                                          )
                                )
                            }
                        }
                    }
                }
                if BuildInfo.isDebugOrTestFlight {
                    SwatchesFormSection()
                        .environmentObject(theme)
                        .environmentObject(prefs)
                        .padding(.top, 8)
                }
                
                Helper_AppIconV()
                    .frame(width: 64, height: 64)
                    .padding(.top, 8)
                
                
            }
        }
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        .task {
            // Keychain won't get involved in previews, only in real runs
            // reads directly from Keychain, no async needed, only await
            userID = IS_PREVIEW
            ? "PREVIEW-DEVICE-ID"
            : await KeychainHelper.shared.getUserIdentifier()
        }
        // if a user cancels or navigates back, the paywall doesn’t keep your UI in a “loading/prompting” state. All mutations occur on the main actor
        .onAppear {
            memVM.setError(nil)
            memVM.shouldPrompt = false
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

// MARK: Swatches
struct SwatchesFormSection: View {
    @EnvironmentObject var theme: ThemeManager
    
    @EnvironmentObject var prefs: AppPreferencesVM
    
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        
        Card {
            //    VStack(alignment: .leading, spacing: 8) {
            Form {
                // NOTE: these are primary control labels; caption is too small/low-contrast
                //                Toggle(isOn: .constant(true) $showSwatches) { T("Show", .label) }
                //        Form {
                // Presented as a table
                Section("Swatches In Use") {
                    Toggle(isOn: $prefs.showSwatches) { T("Show", .label) }
                    if prefs.showSwatches {
                        ThemeSwatches()
                        
                    }
                }
                //        }
                //    }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(p.background)
        }
    }
}

#if DEBUG
#Preview("Settings (dumb)") {
    // Minimal real objects; no debug factories or preview wrappers.
    let theme  = ThemeManager()
    let prefs  = AppPreferencesVM()
    let memVM  = MembershipVM(payment: PaymentService(productIDs: [])) // empty product list = inert
    let focus  = FocusSessionVM(previewMode: true,
                                haptics: NoopHapticsClient(),
                                config: .current)
    let stats  = StatsVM(persistence: PersistenceActor())
    let debug  = DebugRouter() // safe; sheet toggles won’t present in previews
    
    SettingsV(statsVM: stats)
        .environmentObject(theme)
        .environmentObject(prefs)
        .environmentObject(memVM)
        .environmentObject(focus)
        .environmentObject(debug)
        .frame(maxWidth: 430)
}
#endif
