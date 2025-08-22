//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

/// RootView wires shared VMs, persistence, and the single paywall sheet.
struct RootView: View {
    // NOTE: any change in docs, bump LegalConfig.currentVersion to force a re-accept (users will see the gate again)
    /// Legal gate
    @AppStorage(LegalKeys.acceptedVersion) private var acceptedVersion: Int = 0
    @AppStorage(LegalKeys.acceptedAtEpoch) private var acceptedAtEpoch: Double = 0
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    /// bootsraps creates and defines default Category exactly once ever, even across relaunches
    @AppStorage("hasInitializedGeneralCategory") private var hasInitializedGeneralCategory = false
    @AppStorage("hasInitializedArchiveCategory") private var hasInitializedArchiveCategory = false
    
    /// ViewModel as source of truth: Shared services / VMs owned here and injected downward
    @StateObject private var theme: ThemeManager
    @StateObject private var membershipVM: MembershipVM
    @StateObject private var historyVM: HistoryVM
    @StateObject private var focusVM: FocusSessionVM
    @StateObject private var recalibrationVM: RecalibrationVM
    @StateObject private var statsVM: StatsVM
    
    init() {
        /// Inject dependency - all @StateObject created in init only.
        let persistence = PersistenceActor()
        let config = TimerConfig.current
    
        _theme = StateObject(wrappedValue: ThemeManager())
        _membershipVM = StateObject(wrappedValue: MembershipVM())
        
        /// Wire (crate) the same HistoryVM into the FocusSessionVM here in the init, then **assign the weak link once**
        let history = HistoryVM(persistence: persistence)
        let focus = FocusSessionVM(previewMode: false, config: config)
        focus.historyVM = history                               /// ☑️ single wiring point
        
        _historyVM = StateObject(wrappedValue: HistoryVM(persistence: persistence))
        _focusVM = StateObject(wrappedValue: FocusSessionVM(previewMode: false, config: config))
        _recalibrationVM = StateObject(wrappedValue: RecalibrationVM(config: config))
        _statsVM = StateObject(wrappedValue: StatsVM(persistence: persistence))
        
        //FIXME: If StatsVM needs the membershipVM reference, set it post-create:
//        _statsVM.wrappedValue.membershipVM = _membershipVM.wrappedValue
     }
    
    var body: some View {
        TabView {
            /// Lets `RootView` supply navigation via `NavigationStack`, pass in VMs
            NavigationStack {
                FocusSessionActiveV(viewModel: focusVM, recalibrationVM: recalibrationVM)
                    .navigationTitle("Focus")
            }
            .tabItem { Image(systemName: "house.fill") }
            
            NavigationStack {
                HistoryV(viewModel: historyVM)
                    .navigationTitle("History")
            }
            .tabItem {  Image(systemName: "book.fill")  }
            
            NavigationStack {
                SettingsV(viewModel: statsVM)
                    .navigationTitle("Settings")
            }
            .tabItem {  Image(systemName: "gearshape.fill") }
        }
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
               }
           }
           .sheet(isPresented: $showPrivacy) {
               NavigationStack {
                   LegalDocV(title: "Privacy Policy",
                             markdown: MarkdownLoader.load(named: LegalConfig.privacyFile))
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
        /// Provide shared environment objects once, from the root
        .environmentObject(theme)
        .environmentObject(statsVM)
        .environmentObject(membershipVM)
        .environmentObject(historyVM)
    }
}

#Preview {
    RootView()
        .previewTheme()
}
