//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

/*
 === ternary order ( __ ? last : first) "remember as LAF aka Laugh"
 */

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
        // content sits directly on the ZStack background
        let contentWithNoBackground = content
        
        ZStack {
            // Applies full-screen background
            if let g = pal.gradientBackground {
                LinearGradient(
                    colors: g.colors, startPoint: g.start, endPoint: g.end
                )
                .ignoresSafeArea().allowsHitTesting(false).zIndex(0)
            } else {
                pal.background.ignoresSafeArea().allowsHitTesting(false).zIndex(0)
            }
            
            // subtle backdrop for better text contrast -- on recalibrate
            if screen == .recalibrate {
                // Vignette for reliable text contrast
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.18),
                        Color.clear
                    ]),
                    center: .center, startRadius: 0, endRadius: 520
                )
                .blendMode(.multiply)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                // paper-noise texture (tiled)
                Image("Noise64")
//                    .resizable(resizingMode: .tile)   // ⬅️ important: tile, don’t stretch
                    .resizable()
                    .scaledToFit()
                    .opacity(0.06)                   // adjust if too/not subtle enough
                    .blendMode(.overlay)            // merges with bg; doesn't gray out UI
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            
            // actual content view
            contentWithNoBackground
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
    
    // MARK: Light/Dark mode

    
    // MARK: Single sources of truth (owned here, injected downward)
    @StateObject private var theme: ThemeManager
    @StateObject private var memVM: MembershipVM
    @StateObject private var historyVM: HistoryVM
    @StateObject private var focusVM: FocusVM
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
        let notifications   = LiveNotificationClient()
        
        // Plain instances (no self) of Services / VMs
        let theme           = ThemeManager()
        let payments        = PaymentService(productIDs: ["com.argonnesoftware.intention"])
        let membership      = MembershipVM(payment: payments)
        let prefs           = AppPreferencesVM()
        let engine          = HapticsService()
        let liveHaptics     = LiveHapticsClient(prefs: prefs, engine: engine)
        let history         = HistoryVM(persistence: persistence)
        let focus           = FocusVM(
            previewMode: false, haptics: liveHaptics, config: config, persistence: persistence, notifications: notifications
        )
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
            Task { @MainActor in
                await focus?.resetSessionStateForNewStart()
                // ensures session is back to idle & is fresh
                // & recal Completes, the fullScreenCover bound to $focusVM.showRecalibrate dismisses itself
                focus?.showRecalibrate = false
            }
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
        let focusContent    = FocusV(
            focusVM: focusVM,     // not viewModel:focusVM - focusVM: focusVM matches view's property name
            recalibrationVM: recalVM
        )
            .scrollDismissesKeyboard(.interactively)
        
        let focusScreen     = FocusShell(screen: .focus) {
            focusContent
        }
        
        let focusNav        = NavigationStack {
            focusScreen
                // Sets Icon tint
                .tint(palFocus.accent)
                // Force title to p.text otherwise
                .foregroundStyle(palFocus.text)
        }
            .tabItem { Image(systemName: "timer") }
        
        // History Tab
        let historyContent  = HistoryV(viewModel: historyVM)
        let historyScreen   = FocusShell(screen: .history) { historyContent }
        let historyNav      = NavigationStack {
            historyScreen
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
            // Uses focus's default accent (Leaf) - despite "History"
                .tint(palFocus.accent)
            // Force title to p.text otherwise
                .foregroundStyle(palFocus.text)
        }
            .tabItem { Image(systemName: "clock") }
        
        // Settings Tab (drives stats, membership, ...)
        let settingsContent = SettingsV(statsVM: statsVM)
        let settingsScreen  = FocusShell(screen: .settings) { settingsContent }
        let settingsNav     = NavigationStack {
            settingsScreen
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
            // Uses focus's default accent (Leaf) - despite "Settings"
                .tint(palFocus.accent)
            // Force title to p.text otherwise
                .foregroundStyle(palFocus.text)
        }
            .tabItem { Image(systemName: "gear") }
        
        // Tabs built as a *local* keeps long chains out of top-level expression
        let tabs    = TabView {
            focusNav
            historyNav
            settingsNav
        }
            .zIndex(1)
        
        // MARK: - Wrapped content for shares
        // Wrapped to apply shares (apply tab icon coloring, shared toolbars, backgrounds)
        let content = tabs
        // Swipe anywhere to request Debug
            .gesture(
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                guard BuildInfo.isDebugOrTestFlight else { return }
                // left swipe threshold (negative x)
                if value.translation.width < -80 {
                    debug.presentDebugGated(timeout: 75) // X:XX seconds (e.g., 1:15)
                }
            }
)
            .tint(palFocus.accent)
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
            .environmentObject(recalVM)
            .environmentObject(debug)
            .progressOverlay($isBusy, text: "Loading...")
        // MARK: - Applies current screen theme to background
            .toolbarBackground(tabBG, for: .navigationBar)
            .environmentObject(overlayManager)
        //            .sceneHandlers
        //            .launchHandlers
        //            .membershipHandlers
        //            .rootSheets(activeSheet: $activeSheet, memVM: memVM)
        
        // MARK: App lifecycle
        // -- guardrail: scene handling lives at root --
            .onChange(of: scenePhase, perform: { phase in
                // Only set busy for background/inactive phases where a long-running Task might fire
                switch phase {
                case .inactive, .background:
                    isBusy = true
                    Task {
                        defer { isBusy = false }      // Ensure reset after Task completes
                        // -- If there is a pending undo window in History, commit it first so moves persist. --
                        historyVM.commitPendingUndoIfAny()
                        // -- coalesce + persist any pending History saves now --
                        historyVM.flushPendingSaves()
                        // -- snapshot focus session state (not a pause) --
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
                // Set isBusy for the main async launch process
                isBusy = true
                Task {
                    // Ensure reset after All appear tasks
                    defer { isBusy = false }
                    
                    if !IS_PREVIEW {
                        await focusVM.restoreActiveSessionIfAny();
                        // Synchronous, but wrapped in the main Task
                        hapticsEngine.warm()
                        if LegalConsent.needsConsent() {
                            // Keeping the legal sheet on the main thread
                            await MainActor.run { activeSheet = .legal }
                        }
                    } else {
                        // Previews: no ticking, no persistence, no sheets
                    }
                    // implemented as a no-op wrapper than just calls prepare()
                    hapticsEngine.warm()
                    
                    // Wrapped in #if debug to not affect release
#if DEBUG
                    if ProcessInfo.processInfo.environment["RESET_LEGAL_ON_LAUNCH"] == "1" {
                        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedVersion)
                        UserDefaults.standard.removeObject(forKey: LegalKeys.acceptedAtEpoch)
                        if !IS_PREVIEW { activeSheet = .legal }
                    }
#endif
                    
                }
            }
        
        // MARK: Sheets
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .legal:
                    LegalAgreementSheetV(
                        onAccept: {
                            Task { @MainActor in
                                //                                LegalConsent.recordAcceptance()
                                acceptedVersion = LegalConfig.currentVersion
                                acceptedAtEpoch = Date().timeIntervalSince1970
                                activeSheet = nil
                            }
                        },
                        onShowTerms: { Task { @MainActor in activeSheet = .terms } },
                onShowPrivacy: { Task { @MainActor in activeSheet = .privacy } },
                        onShowMedical: { Task { @MainActor in activeSheet = .medical } }
                    )
                    .environmentObject(theme)
                    
                case .terms:
                    NavigationStack {
                        LegalDocV(
                            title: "Terms of Use",
                            markdown: MarkdownLoader.load(named: LegalConfig.termsFile),
                            palette: theme.palette(for: .settings)
                        )
                    }
                    .environmentObject(theme)
                    
                case .privacy:
                    NavigationStack {
                        LegalDocV(
                            title: "Privacy Policy",
                            markdown: MarkdownLoader.load(named: LegalConfig.privacyFile),
                            palette: theme.palette(for: .settings)
                        )
                    }
                    .environmentObject(theme)
                    
                case .medical:
                    NavigationStack {
                        LegalDocV(
                            title: "Wellness Disclaimer",
                            markdown: MarkdownLoader.load(named: LegalConfig.medicalFile),
                            palette: theme.palette(for: .settings)
                        )
                    }
                    .environmentObject(theme)
                }
            }
        // ========== DEBUG PRESENTATION WIRING ==========
            .fullScreenCover(isPresented: $debug.showDebug) {
                NavigationStack {
                    DebugAndPathsV()
                        .environmentObject(theme)
                        .environmentObject(memVM)
                        .environmentObject(historyVM)
                        .environmentObject(prefs)
                        .environmentObject(hapticsEngine)
                        .environmentObject(focusVM)
                        .environmentObject(recalVM)
        
                        .navigationTitle("Debug")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Close") { debug.showDebug = false }
                            }
                        }
                }
            }
        // Recalibration "sheet" as a full-screen chrome for debug
            .fullScreenCover(isPresented: $debug.showRecalibration) {
                RecalibrationSheetChrome(onClose: {
                    Task { @MainActor in debug.showRecalibration = false }
                }) {
                    // Use a minimal mock for debug rendering ONLY here.
                    // (Does not mutate live session state.)
                    RecalibrationV(vm: RecalibrationVM.mockForDebug())
                }
                .environmentObject(theme)
                .environmentObject(prefs)
            }
        
            .fullScreenCover(isPresented: memVM.showSheetBinding) {
                MembershipSheetChrome(onClose: {
                    // close the chrome and tell the VM to stop prompting
                    Task { @MainActor in memVM.shouldPrompt = false }
                }) {
                    NavigationStack {
                        MembershipSheetV()
                            .navigationBarHidden(true)  // chrome owns close
                            .environmentObject(memVM)
                            .environmentObject(theme)
                            .environmentObject(prefs)
                    }
                    .interactiveDismissDisabled(false)
                }
                //        .onDisappear { memVM.shouldPrompt = false }
            }
        // MARK: onChange ...runs on Main
            .onChange(of: debug.showError) { show in
                if show {
                    Task { @MainActor in
                    overlayManager.debugErrorTitle = debug.errorTitle
                    overlayManager.debugErrorMessage = debug.errorMessage
                    overlayManager.isShowingDebugError = true
                    debug.showError = false
                }
                }
            }
    }
}
