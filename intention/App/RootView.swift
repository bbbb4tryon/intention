//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//
//What’s happening (why it “finishes”)


import SwiftUI

// MARK: - FocusShell

/// Centralizes per-screen chrome (backgrounds, overlays, sheets)
/// Keep it under 15 lines: Swift won't yell and this avoids deep view chains
struct FocusShell<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    let screen: ScreenName
    
    @ViewBuilder var content: Content
    
    var body: some View {
        let pal = theme.palette(for: screen)
        // card/surface under widgets
        let backgrounded = content.background(pal.surface)
        
        ZStack {
            if let g = pal.gradientBackground {
                LinearGradient(
                    colors: g.colors, startPoint: g.start, endPoint: g.end
                )
                    .ignoresSafeArea()
            } else {
                pal.background.ignoresSafeArea()
            }
            backgrounded
        }
    }
}

// MARK: - RootSheet

/// sheets presented from the root - Swift won't yell and this avoids deep view chains
enum RootSheet: Identifiable, Equatable {
    case legal, terms, privacy, medical
    
    var id: String {
        switch self {
        case .legal: return "legal"
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


// MARK: Global AppErrorOverlayManager
// Use MainActor to ensure all state changes happen on the main thread safely.
@MainActor
final class AppOverlayManager: ObservableObject {
    @Published var debugErrorTitle: String = ""
    @Published var debugErrorMessage: String = ""
    @Published var isShowingDebugError = false
    
    init() {
        // This sets up the observer when the manager is initialized.
        NotificationCenter.default.addObserver(
            forName: .debugShowSampleError, object: nil, queue: nil // Ensures UI updates happen safely
        ) { [weak self] note in
            Task { @MainActor in
            guard let self = self else { return }
            // Extract the data payload + self.Update the state to trigger the overlay
            let userInfo = note.userInfo
                self.debugErrorTitle = userInfo?[DebugNotificationKey.errorTitle] as? String ?? "Debug Error"
                self.debugErrorMessage = userInfo?[DebugNotificationKey.errorMessage] as? String ?? "No debug message provided."
            self.isShowingDebugError = true
            }
        }
    }
}

/// App entry. Owns and wires shared VMs/actors. Presents paywall and legal.
/// Keeps single sources of truth at the root and centralizes scene handling.
struct RootView: View {
    
    // MARK: AppStorage (legal gate)
    // Last accepted legal version.
    @AppStorage(LegalKeys.acceptedVersion) private var acceptedVersion: Int = 0
    // Acceptance timestamp (epoch seconds).
    @AppStorage(LegalKeys.acceptedAtEpoch) private var acceptedAtEpoch: Double = 0
    
    // MARK: presentation
    // Which root-level sheet is visible (legal, membership, etc).
    @State private var activeSheet: RootSheet?
    @State private var isShowingMembershipDebug = false
    // Global "busy, Loading" overlay.
    @State private var isBusy = false
    
    // MARK: Injecting Global ErrorOverlay Manager
    @StateObject private var overlayManager = AppOverlayManager()
    
    // MARK: Scene
    /// Scene phase guardrail: pause timers, flush history, warms haptics.
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: Single sources of truth (owned here, injected downward)
    @StateObject private var theme: ThemeManager
    @StateObject private var memVM: MembershipVM
    @StateObject private var historyVM: HistoryVM
    @StateObject private var focusVM: FocusSessionVM
    @StateObject private var recalVM: RecalibrationVM
    @StateObject private var statsVM: StatsVM
    @StateObject private var prefs: AppPreferencesVM
    @StateObject private var hapticsEngine: HapticsService // warmed generators (UI object)
    @StateObject private var debug = DebugRouter()
    
    /// Builds once: create infrastructure: actors/services, wire VM for "when", actors for "how", and assign to `@StateObject` wrappers.
    init() {
        // Infra actors/services
        let persistence     = PersistenceActor()
        let config          = TimerConfig.current
        
        // Plain instances (no self) of Services / VMs
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
        
        // Wiring
        focus.historyVM     = history    // Focus writes completions into History
        stats.memVM         = membership // Stats can query membership state

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
        
        // Assign "wrappers" `_StateObject` backing vars
        _theme          = StateObject(wrappedValue: theme)
        _memVM          = StateObject(wrappedValue: membership)
        _historyVM      = StateObject(wrappedValue: history)
        _focusVM        = StateObject(wrappedValue: focus)
        _recalVM        = StateObject(wrappedValue: recal)
        _statsVM        = StateObject(wrappedValue: stats)
        _prefs          = StateObject(wrappedValue: prefs)
        _hapticsEngine  = StateObject(wrappedValue: engine)
    }
    
    // MARK: Body
    var body: some View {
        // shared palette locals help calm the swift type-checker
        let palFocus        = theme.palette(for: .focus)
        let _               = theme.palette(for: .history)
        let _               = theme.palette(for: .settings)
        let _               = theme.palette(for: .recalibrate)
        let _               = theme.palette(for: .membership)
        let tabBG           = palFocus.background.opacity(0.88) // Makes tab bar match app theme (iOS 16+)
        
        
        // Focus Tab
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
        
        // History Tab
        let historyContent  = HistoryV(viewModel: historyVM)
        let historyScreen   = FocusShell(screen: .history) { historyContent }
        let historyNav      = NavigationStack {
            historyScreen
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
        }
            .tabItem { Image(systemName: "clock") }
        
        // Settings Tab (drives stats, membership, ...)
        let settingsContent = SettingsV(statsVM: statsVM)
        let settingsScreen  = FocusShell(screen: .settings) { settingsContent }
        let settingsNav     = NavigationStack {
            settingsScreen
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
            .tabItem { Image(systemName: "gear") }
        
        // Tabs built as a *local* keeps long chains out of top-level expression
        let tabs    = TabView {
            focusNav
            historyNav
            settingsNav
        }
        
        // Wrapped to apply shares (apply tab icon coloring, shared toolbars, backgrounds)
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
            .environmentObject(debug)
            .progressOverlay($isBusy, text: "Loading...")
        // Applies current screen theme to background
            .toolbarBackground(tabBG, for: .navigationBar)
            .environmentObject(overlayManager)
//            .sceneHandlers
//            .launchHandlers
//            .membershipHandlers
//            .rootSheets(activeSheet: $activeSheet, memVM: memVM)
        
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
//            .onChange(of: memVM.shouldPrompt) { show in
//                if show, activeSheet == nil { activeSheet = .membership }
//            }
//            .onChange(of: activeSheet) { sheet in
//                if sheet == nil, memVM.shouldPrompt { activeSheet = .membership }
//            }
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
                    .environmentObject(theme)
                    
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
        // ========== DEBUG PRESENTATION WIRING ==========
        // Recalibration "sheet" as a full-screen chrome for debug
            .fullScreenCover(isPresented: $debug.showRecalibration) {
                RecalibrationSheetChrome(onClose: { debug.showRecalibration = false }) {
                    // Use a minimal mock for debug rendering ONLY here.
                    // (Does not mutate live session state.)
                    RecalibrationV(vm: RecalibrationVM.mockForDebug())
                }
                .environmentObject(theme)
            }

            // Organizer overlay using LIVE history categories (no mocks).
            // We pass a Binding into OrganizerOverlayScreen so reordering acts on your real data.
            .fullScreenCover(isPresented: $debug.showOrganizer) {
                OrganizerOverlayChrome(onClose: { debug.showOrganizer = false }) {
                    OrganizerOverlayScreen(
                        categories: Binding(
                            get: { historyVM.categories },
                            set: { historyVM.categories = $0 }
                        ),
                        onMoveTile: { tile, sourceID, destinationID in
                            historyVM.moveTileBetweenCategories(tile, fromCategory: sourceID, toCategory: destinationID)
                        },
                        onReorder: { newTiles, catID in
                            historyVM.reorderTiles(newTiles, in: catID)
                            
                        },
                        onDone: { debug.showOrganizer = false }
                    )
                }
                .environmentObject(theme)
            }
        
        
            .fullScreenCover(isPresented: memVM.showSheetBinding) {
                MembershipSheetChrome(onClose: {
                    // close the chrome and tell the VM to stop prompting
                    memVM.shouldPrompt = false
                }) {
                    NavigationStack {
                        MembershipSheetV()
                            .navigationBarHidden(true)  // chrome owns close
                            .environmentObject(memVM)
                            .environmentObject(theme)
                    }
                    .interactiveDismissDisabled(false)
                }
                //        .onDisappear { memVM.shouldPrompt = false }
            }

            // Membership debug simply reuses your root sheet choreography
//            .onChange(of: debug.showMembership) { want in
//                if want { activeSheet = .membership; debug.showMembership = false }
//            }

            // Route debug errors through the same global overlayManager
            .onChange(of: debug.showError) { show in
                if show {
                    overlayManager.debugErrorTitle = debug.errorTitle
                    overlayManager.debugErrorMessage = debug.errorMessage
                    overlayManager.isShowingDebugError = true
                    debug.showError = false
                }
            }
        
//            .onReceive(NotificationCenter.default.publisher(for: .devOpenMembership)) { _ in
//                        isShowingMembershipDebug = true
//                    }
//        // The Global Presentation: Use .overlay to float over all content
//                .overlay {
//                    if overlayManager.isShowingDebugError {
//                        ErrorOverlay(
////                            title: overlayManager.debugErrorTitle,
//                            displayMessage: overlayManager.debugErrorMessage,
//                            dismissAction: { overlayManager.isShowingDebugError = false }
//                        )
//                        // Use a standard, quick animation for a polished feel
//                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
//                    }
//                }
    }
}

//private extension View {
//    var sceneHandlers: some View { modifier(SceneHandlers()) }
//    var launchHandlers: some View { modifier(LaunchHandlers()) }
//    func membershipHandlers(activeSheet: Binding<RootSheet?>, memVM: MembershipVM) -> some View {
//            modifier(MembershipHandlers(activeSheet: activeSheet, memVM: memVM))
//        }
//        func rootSheets(activeSheet: Binding<RootSheet?>, memVM: MembershipVM) -> some View {
//            modifier(RootSheets(activeSheet: activeSheet, memVM: memVM))
//        }
//}
