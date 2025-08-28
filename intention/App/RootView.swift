//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

/// RootView wires shared VMs, persistence, and the single paywall sheet.
struct RootView: View {
    // NOTE: any change in docs, bump LegalConfig.currentVersion to force a re-accept (users see gate again)
    /// Legal gate
    @AppStorage(LegalKeys.acceptedVersion) private var acceptedVersion: Int = 0
    @AppStorage(LegalKeys.acceptedAtEpoch) private var acceptedAtEpoch: Double = 0
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    /// bootstraps creates and defines default Category exactly once ever, even across relaunches
    @AppStorage("hasInitializedGeneralCategory") private var hasInitializedGeneralCategory = false
    @AppStorage("hasInitializedArchiveCategory") private var hasInitializedArchiveCategory = false
    
    /// ViewModel as source of truth: Shared services / VMs owned here and injected downward
    @StateObject private var theme: ThemeManager
    @StateObject private var membershipVM: MembershipVM
    @StateObject private var historyVM: HistoryVM
    @StateObject private var focusVM: FocusSessionVM
    @StateObject private var recalibrationVM: RecalibrationVM
    @StateObject private var statsVM: StatsVM
    @StateObject private var prefs: AppPreferencesVM
    @StateObject private var haptics: HapticsService     /// One 'warmed' main-actor engine per UI scene, see .environmentObject()

    
    init() {
        /// Inject dependency - all @StateObject created in init only.
        /// Make plain local instances (no self involved) as in let live = LiveHapticsClients( prefs:  _pref...
        let persistence     = PersistenceActor()
        let config          = TimerConfig.current
        
        let theme           = ThemeManager()
        let membership    = MembershipVM()
        let prefs          = AppPreferencesVM()
        let engine         = HapticsService()
        let liveHaptics    = LiveHapticsClient(prefs: prefs, engine: engine)
        let history         = HistoryVM(persistence: persistence)
        let focus           = FocusSessionVM(previewMode: false, haptics: liveHaptics, config: config)
        let recal           = RecalibrationVM(haptics: liveHaptics, config: config, persistence: persistence)
        let stats           = StatsVM(persistence: persistence)
        
        _theme = StateObject(wrappedValue: ThemeManager())
        _membershipVM = StateObject(wrappedValue: MembershipVM())
        
        /// Wire (create) the same HistoryVM into the FocusSessionVM here in the init, then **assign the weak link once**; Locals only
        focus.historyVM = history                               /// ☑️ single wiring point
        stats.membershipVM = membership
        
        /// Assign to the wrappers
        _theme          = StateObject(wrappedValue: theme)
        _membershipVM   = StateObject(wrappedValue: membership)
        _historyVM      = StateObject(wrappedValue: history)
        _focusVM        = StateObject(wrappedValue: focus)
        _recalibrationVM = StateObject(wrappedValue: recal)
        _statsVM        = StateObject(wrappedValue: stats)
        _prefs          = StateObject(wrappedValue: prefs)
        _haptics        = StateObject(wrappedValue: engine)
        
        //FIXME: If StatsVM needs the membershipVM reference, set it post-create:
        //        _statsVM.wrappedValue.membershipVM = _membershipVM.wrappedValue
    }
    
    var body: some View {
        
        /// Makes tab bar match app theme (iOS 16+)
        let tabBG = theme.palette(for: .homeActiveIntentions).background.opacity(0.8)
        
        TabView {
            /// allows `RootView` supply navigation via `NavigationStack`, pass in VMs
            NavigationStack {
                FocusSessionActiveV(viewModel: focusVM, recalibrationVM: recalibrationVM)
                    .navigationTitle("Focus")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(theme.palette(for: .homeActiveIntentions).background, for: .navigationBar)
                    .toolbarBackground(tabBG, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(tabBG, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .friendlyHelper()
            }
            .tabItem { Image(systemName: "house.fill") }
            
            NavigationStack {
                HistoryV(viewModel: historyVM)
                    .navigationTitle("History")
                    .accessibilityAddTraits(.isHeader)
            }
            .tabItem {  Image(systemName: "book.fill").accessibilityAddTraits(.isHeader)  }
            
            NavigationStack {
                SettingsV(viewModel: statsVM)
                    .navigationTitle("Settings")
                    .accessibilityAddTraits(.isHeader)
            }
            .tabItem {  Image(systemName: "gearshape.fill").accessibilityAddTraits(.isHeader) }
        }
        
        /// consistent color schemes for app tab bar
        .toolbarBackground(tabBG, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        /// consistent color schemes for nav bars
        .toolbarBackground(tabBG, for: .navigationBar)
        
        
        .sheet(isPresented: $membershipVM.shouldPrompt) {
            MembershipSheetV()
                .environmentObject(membershipVM)
                .environmentObject(theme)
        }
           // Inline doc presentation (reuses your LegalDocV/Markdown files)
           .sheet(isPresented: $showTerms) {
               NavigationStack {
                   LegalDocV(title: "Terms of Use",
                             markdown: MarkdownLoader.load(named: LegalConfig.termsFile))
                   .accessibilityAddTraits(.isHeader)
               }
           }
           .sheet(isPresented: $showPrivacy) {
               NavigationStack {
                   LegalDocV(title: "Privacy Policy",
                             markdown: MarkdownLoader.load(named: LegalConfig.privacyFile))
                   .accessibilityAddTraits(.isHeader)
               }
           }
        .onAppear {
            /// First-run categories
            if !hasInitializedGeneralCategory {
                historyVM.ensureGeneralCategory()
                hasInitializedGeneralCategory = true
                debugPrint("Default category initialized from RootView")
            }
            if !hasInitializedArchiveCategory {
                historyVM.ensureArchiveCategory()
                hasInitializedArchiveCategory = true
                debugPrint("Archive category initialized from RootView")
            }
        }
        /// Provide shared environment objects once, from the root/ so SwiftUI views can call it easily if they want to.
        .environmentObject(theme)
        .environmentObject(statsVM)
        .environmentObject(membershipVM)
        .environmentObject(historyVM)
        .environmentObject(prefs)
        .environmentObject(haptics)
    }
}

#Preview {
    RootView()
        .previewTheme()
}
