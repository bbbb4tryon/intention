//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

// MARK: - FocusShell
/// Tiny shell that centralizes shared chrome per screen (backgrounds, overlays).
/// Keep it intentionally small so it composes well and doesn't re-introduce big chains.
struct FocusShell<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    
    
    @ViewBuilder var content: Content
    
    var body: some View {
        let pal = theme.palette(for: screen)
        //        let base = content
        let backgrounded = content.background(pal.surface)    // card/surface under widgets
        
        ZStack {
            if let g = pal.gradientBackground {
                LinearGradient(colors: g.colors, startPoint: g.start, endPoint: g.end)
                    .ignoresSafeArea()
            } else {
                pal.background.ignoresSafeArea()
            }
            backgrounded
        }
    }
}

// MARK: - sheets presented from the root
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

/// App entry content. Owns and wires shared VMs/actors; hosts the single paywall/legal sheets.
/// - Keeps VMs at the root (single source of truth)
/// - Centralizes scene-phase handling and background chrome via `FocusShell`
struct RootView: View {
    
    // MARK: AppStorage – legal gate
    /// Last accepted legal version.
    @AppStorage(LegalKeys.acceptedVersion) private var acceptedVersion: Int = 0
    /// Acceptance timestamp (epoch seconds).
    @AppStorage(LegalKeys.acceptedAtEpoch) private var acceptedAtEpoch: Double = 0
    
    // MARK: presentation
    /// Which root-level sheet is visible (legal, membership, etc).
    @State private var activeSheet: RootSheet?
    /// Global busy overlay.
    @State private var isBusy = false
    
    // MARK: Scene
    /// Scene phase guardrail: pause timers, flush history, warm haptics.
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: Single source of truth (owned here, injected downward)
    @StateObject private var theme: ThemeManager
    @StateObject private var memVM: MembershipVM
    @StateObject private var historyVM: HistoryVM
    @StateObject private var focusVM: FocusSessionVM
    @StateObject private var recalVM: RecalibrationVM
    @StateObject private var statsVM: StatsVM
    @StateObject private var prefs: AppPreferencesVM
    @StateObject private var hapticsEngine: HapticsService            // warmed generators (UI object)
    
    /// Build once: create actors/services, wire VMs, and assign to `@StateObject` wrappers.
    init() {
        // 1) Infra actors/services
        let persistence     = PersistenceActor()
        let config          = TimerConfig.current
        
        // 2) Plain instances (no self)
        let theme           = ThemeManager()
        let payments        = PaymentService(productIDs: ["com.argonnesoftware.intention"])
        let membership      = MembershipVM(payment: payments)
        let prefs           = AppPreferencesVM()
        let engine          = HapticsService()
        let liveHaptics     = LiveHapticsClient(prefs: prefs, engine: engine)
        
        let history         = HistoryVM(persistence: persistence)
        let focus           = FocusSessionVM(previewMode: false, haptics: liveHaptics, config: config)
        let recal           = RecalibrationVM(haptics: liveHaptics)
        let stats           = StatsVM(persistence: persistence)
        
        // 3) Cross-VM wiring (focus→history, stats→membership)
        focus.historyVM     = history                               // Focus writes completions into History
        stats.memVM         = membership                            // Stats can query membership state
        
        // 4) Recalibration completion hook → log + reset
        recal.onCompleted = { [weak stats, weak focus] (mode: RecalibrationMode) in
            guard let stats = stats else { return }
            let texts = focus?.tiles.map(\.text) ?? []
            stats.logSession(CompletedSession(
                date: .now,
                tileTexts: texts,
                recalibration: mode
            ))
            Task { @MainActor in await focus?.resetSessionStateForNewStart() }
        }
        
        // 5) Assign to `_StateObject` backing vars aka "wrappers"
        _theme          = StateObject(wrappedValue: theme)
        _memVM          = StateObject(wrappedValue: membership)
        _historyVM      = StateObject(wrappedValue: history)
        _focusVM        = StateObject(wrappedValue: focus)
        _recalVM        = StateObject(wrappedValue: recal)
        _statsVM        = StateObject(wrappedValue: stats)
        _prefs          = StateObject(wrappedValue: prefs)
        _hapticsEngine  = StateObject(wrappedValue: engine)
    }
    
    // MARK: - body
    var body: some View {
        // shared palette locals help calm the swift type-checker
        let palFocus        = theme.palette(for: .focus)
        let _               = theme.palette(for: .history)
        let _               = theme.palette(for: .settings)
        let _               = theme.palette(for: .recalibrate)
        let _               = theme.palette(for: .membership)
        let tabBG           = palFocus.background.opacity(0.88)          // Makes tab bar match app theme (iOS 16+)
        
        
        // Focus tab
        let focusContent    = FocusSessionActiveV(
            focusVM: focusVM,     // not viewModel:focusVM - focusVM: focusVM matches view's property name
            recalibrationVM: recalVM
        )
            .scrollDismissesKeyboard(.interactively)
        
        let focusScreen     = FocusShell(screen: .focus) {
            focusContent
        }
        
        let focusNav        = NavigationStack {
            focusScreen
                .navigationTitle("Focus")
                .navigationBarTitleDisplayMode(.inline)
        }
            .tabItem { Image(systemName: "timer") }
        
        // History tab
        let historyContent  = HistoryV(viewModel: historyVM)
        let historyScreen   = FocusShell(screen: .history) { historyContent }
        let historyNav      = NavigationStack {
            historyScreen
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
        }
            .tabItem { Image(systemName: "clock") }
        
        // Settings tab (drives stats, membership, ...)
        let settingsContent = SettingsV(statsVM: statsVM)
        let settingsScreen  = FocusShell(screen: .settings) { settingsContent }
        let settingsNav     = NavigationStack {
            settingsScreen
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
            .tabItem { Image(systemName: "gear") }
        
        // Tabs built as a *local* keeps long chains out of top-level expression
        // Wrapped here to apply shared toolbars, backgrounds, tab icon coloring
        let tabs    = TabView {
            focusNav
            historyNav
            settingsNav
        }
        
        // Wrap here to apply shared toolbars, backgrounds
        let content = tabs
            .tint(palFocus.primary)
            .toolbarBackground(tabBG, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        
        content
        // the shared environment
            .environmentObject(theme)
            .environmentObject(statsVM)
            .environmentObject(memVM)
            .environmentObject(historyVM)
            .environmentObject(prefs)
            .environmentObject(hapticsEngine)
            .environmentObject(focusVM)
            .progressOverlay($isBusy, text: "Loading...")
        
        // Keep nav bars coherent with theme - applied per screen via FocusShell/background
            .toolbarBackground(tabBG, for: .navigationBar)
        
        // MARK: App lifecycle (guardrail: scene handling lives at root)
            .onChange(of: scenePhase, perform: { phase in
                // Only set busy for background/inactive phases where a long-running Task might fire
                switch phase {
                case .inactive, .background:
                    isBusy = true
                    Task {
                        defer { isBusy = false }      // Ensure reset after Task completes
                        // 1) coalesce + persist any pending History saves now
                        historyVM.flushPendingSaves()
                        // 2) snapshot focus session state (not a pause)
                        await focusVM.suspendTickingForBackground()
                        isBusy = false
                    }
                
                // Active state only calls short synchronous functions
                case .active:
                    isBusy = true
                    // 3) recompute remaining (time) from snapshot & resume UI ticking if needed
                    recalVM.appDidBecomeActive()
                    Task {
                        await focusVM.resumeTickingAfterForeground(); isBusy = false
                    }
                default: break
                }
            })
        // MARK: App launch + restore any active session state + legal gate
            .onAppear {
                // 1) Set isBusy for the main async launch process
                isBusy = true
                Task {
                    defer { isBusy = false }      // Ensure reset after All onAppear tasks
                    
                    await focusVM.restoreActiveSessionIfAny();
                    hapticsEngine.warm()                        // Synchronous, but wrapped in the main Task
                    
                    if LegalConsent.needsConsent() {
                        // Keep the legal sheet on the main thread
                        await MainActor.run { activeSheet = .legal }
                    }
                }
                
                hapticsEngine.warm()        // implemented as a no-op wrapper than just calls prepare()
                
                // Wrapped in #if debug to not affect release
#if DEBUG
                if ProcessInfo.processInfo.environment["RESET_LEGAL_ON_LAUNCH"] == "1" {
                    UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedVersion)
                    UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedAtEpoch)
                    activeSheet = .legal
                }
#endif

            }
        
        // Membership prompt choreography
        ///FIXME: remove one of the membership because they're "re"-presented?
            .onChange(of: memVM.shouldPrompt) { show in
                if show, activeSheet == nil { activeSheet = .membership }
            }
            .onChange(of: activeSheet) { sheet in
                if sheet == nil, memVM.shouldPrompt { activeSheet = .membership }
            }
        // MARK: Sheets
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
                        onShowTerms: { activeSheet = .terms },
                        onShowPrivacy: { activeSheet = .privacy },
                        onShowMedical: { activeSheet = .medical }
                    )
                    
                case .membership:
                    NavigationStack {
                        MembershipSheetV()
                            .environmentObject(memVM)
                            .environmentObject(theme)
                    }
                    .onDisappear { memVM.shouldPrompt = false }
                    
                case .terms:
                    NavigationStack {
                        LegalDocV(
                            title: "Terms of Use",
                            markdown: MarkdownLoader.load(named: LegalConfig.termsFile)
                        )
                    }
                    
                case .privacy:
                    NavigationStack {
                        LegalDocV(
                            title: "Privacy Policy",
                            markdown: MarkdownLoader.load(named: LegalConfig.privacyFile)
                        )
                    }
                    
                case .medical:
                    NavigationStack {
                        LegalDocV(
                            title: "Wellness Disclaimer",
                            markdown: MarkdownLoader.load(named: LegalConfig.medicalFile)
                        )
                    }
                }
            }
    }
}


#if DEBUG
#Preview {
    RootView()
        .previewTheme()
}
#endif
