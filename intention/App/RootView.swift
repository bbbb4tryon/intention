//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

enum RootSheet: Identifiable, Equatable {
    case legal, membership, terms, privacy, medical
    var id: String {
        switch self {
        case .legal: return "legal"
        case .membership: return "membership"
        case .terms: return "terms"
        case .privacy: return "privacy"
        case .medical: return "medical"
        }
    }
}

#if DEBUG
extension RootView {
    func _resetLegalGate() {
        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedVersion)
        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedAtEpoch)
        activeSheet = .legal
    }
}
#endif


/// RootView wires shared VMs, persistence, and the single paywall sheet.
struct RootView: View {
    // NOTE: any change in docs, bump LegalConfig.currentVersion to force a re-accept (users see gate again)
    /// Legal gate
    @AppStorage(LegalKeys.acceptedVersion) private var acceptedVersion: Int = 0
    @AppStorage(LegalKeys.acceptedAtEpoch) private var acceptedAtEpoch: Double = 0
    @State private var activeSheet: RootSheet? = nil
    @Environment(\.scenePhase) private var scenePhase
    
    private var ifLegalGateNeeded: Bool { LegalConsent.needsConsent() }
//
//    /// bootstraps creates and defines default Category exactly once ever, even across relaunches
//    @AppStorage("hasInitializedGeneralCategory") private var hasInitializedGeneralCategory = false
//    @AppStorage("hasInitializedArchiveCategory") private var hasInitializedArchiveCategory = false
    
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
        let engine         = HapticsService()       // warmed generators
        let liveHaptics    = LiveHapticsClient(prefs: prefs, engine: engine)
        let history         = HistoryVM(persistence: persistence)
        let focus           = FocusSessionVM(previewMode: false, haptics: liveHaptics, config: config)
        let recal           = RecalibrationVM(haptics: liveHaptics)
        let stats           = StatsVM(persistence: persistence)
        
        _theme = StateObject(wrappedValue: ThemeManager())
        _membershipVM = StateObject(wrappedValue: MembershipVM())
        
        /// Wire (create) the same HistoryVM into the FocusSessionVM here in the init, then **assign the weak link once**; Locals only
        focus.historyVM = history                               /// ☑️ single wiring point
        stats.membershipVM = membership
        
        // Wire recalibration completion -> Stats
        recal.onCompleted = { [weak stats, weak focus] mode in
            // RecalibrationVM calls this on the MainActor - safe for UI VMs
            guard let stats = stats else { return }
               let texts = focus?.tiles.map(\.text) ?? []   // source-of-truth tile texts from FocusSessionVM

               // Log a “completed session” with recalibration attached
               stats.logSession(CompletedSession(
                   date: .now,
                   tileTexts: texts,
                   recalibration: mode
               ))

               // Optional: reset the focus flow so the user is ready to add two new tiles
               Task { @MainActor in
                   try? await focus?.resetSessionStateForNewStart()
               }
            
        }
        
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
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset Legal") { _resetLegalGate() }
                }
            }
            #endif
            
            NavigationStack {
                HistoryV(viewModel: historyVM)
                    .navigationTitle("History")
                    .accessibilityAddTraits(.isHeader)
            }
            .tabItem {  Image(systemName: "book.fill").accessibilityAddTraits(.isHeader)  }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset Legal") { _resetLegalGate() }
                }
            }
            #endif
            
            NavigationStack {
                SettingsV(viewModel: statsVM)
                    .navigationTitle("Settings")
                    .accessibilityAddTraits(.isHeader)
            }
            .tabItem {  Image(systemName: "gearshape.fill").accessibilityAddTraits(.isHeader) }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset Legal") { _resetLegalGate() }
                }
            }
            #endif
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset Legal") { _resetLegalGate() }
            }
        }
        #endif

        /// consistent color schemes for app tab bar
        .toolbarBackground(tabBG, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        /// consistent color schemes for nav bars
        .toolbarBackground(tabBG, for: .navigationBar)
        
//        
//        .sheet(isPresented: $membershipVM.shouldPrompt) {
//            MembershipSheetV()
//                .environmentObject(membershipVM)
//                .environmentObject(theme)
//        }
           // Legal gate sheet (reuses LegalDocV/Markdown files)
//           .sheet(isPresented: $showLegalGate) {
//               NavigationStack {
//                   LegalDocV(title: "Terms of Use",
//                             markdown: MarkdownLoader.load(named: LegalConfig.termsFile))
//                   .accessibilityAddTraits(.isHeader)
//               }
//           }
//           .sheet(isPresented: $showPrivacy) {
//               NavigationStack {
//                   LegalDocV(title: "Privacy Policy",
//                             markdown: MarkdownLoader.load(named: LegalConfig.privacyFile))
//                   .accessibilityAddTraits(.isHeader)
//               }
//           }
        .onAppear {
            if ifLegalGateNeeded { activeSheet = .legal }
            if ProcessInfo.processInfo.environment["RESET_LEGAL_ON_LAUNCH"] == "1" {
                UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedVersion)
                UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedAtEpoch)
                activeSheet = .legal
            }
            
//            /// First-run categories
//            if !hasInitializedGeneralCategory {
//                historyVM.ensureGeneralCategory()
//                hasInitializedGeneralCategory = true
//                debugPrint("Default category initialized from RootView")
//            }
//            if !hasInitializedArchiveCategory {
//                historyVM.ensureArchiveCategory()
//                hasInitializedArchiveCategory = true
//                debugPrint("Archive category initialized from RootView")
//            }
        }
        .onChange(of: scenePhase ) { phase in
            if phase == .inactive || phase == .background {
                historyVM.flushPendingSaves()
            }
        }
        .onChange(of: membershipVM.shouldPrompt) { show in
            // Queue membership only if nothing else (e.g., Legal) is showing.
            if show, activeSheet == nil { activeSheet = .membership }
        }
        .onChange(of: activeSheet) { sheet in
            // If Legal just dismissed and membership is pending, present it next.
            if sheet == nil, membershipVM.shouldPrompt { activeSheet = .membership }
        }
        
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .legal:
                LegalAgreementSheetV(
                    onAccept: {
                        LegalConsent.recordAcceptance()
                        acceptedVersion = LegalConfig.currentVersion
                        acceptedAtEpoch = Date().timeIntervalSince1970
                        activeSheet = nil
                    },
                    onShowTerms:   { activeSheet = .terms },
                    onShowPrivacy: { activeSheet = .privacy },
                    onShowMedical: { activeSheet = .medical }
                )
                
            case .membership:
                NavigationStack {
                    MembershipSheetV()
                        .environmentObject(membershipVM)
                        .environmentObject(theme)
                }
                    .onDisappear { membershipVM.shouldPrompt = false }
                
            case .terms:
                NavigationStack {
                    LegalDocV(title: "Terms of Use",
                              markdown: MarkdownLoader.load(named: LegalConfig.termsFile))
                }
                
            case .privacy:
                NavigationStack {
                    LegalDocV(title: "Privacy Policy",
                              markdown: MarkdownLoader.load(named: LegalConfig.privacyFile))
                }
                
            case .medical:
                NavigationStack {
                    LegalDocV(title: "Wellness Disclaimer",
                              markdown: MarkdownLoader.load(named: LegalConfig.medicalFile))
                }
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

#if DEBUG
#Preview {
    RootView()
        .previewTheme()
}
#endif
