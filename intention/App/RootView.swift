//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

struct RootView: View {
    // creates and defines default Category exactly once ever, even across relaunches
    @AppStorage("hasInitializedDefaultCategory") private var hasInitializedDefaultCategory = false
    
    // Shared, reusable instance injected once, then passed into each viewModel: categories, stats are part of a shared domain
    let persistence = PersistenceActor()
    private let config = TimerConfig.current
    
    /// ViewModel is the source of truth
    @StateObject private var historyVM: HistoryVM
    @StateObject private var focusVM: FocusSessionVM
    @StateObject private var recalibrationVM = RecalibrationVM()
    @StateObject private var statsVM: StatsVM
    @StateObject private var userService = UserService()
    @StateObject private var membershipVM = MembershipVM()
    
    init() {
        /// Inject dependency so HistoryV can access tiles from the focusVM, etc
        let persistence = PersistenceActor()
        let config = TimerConfig.current
        _historyVM = StateObject(wrappedValue: HistoryVM(persistence: persistence))
        _focusVM = StateObject(wrappedValue: FocusSessionVM(previewMode: false, config: config))
        _recalibrationVM = StateObject(wrappedValue: RecalibrationVM(config: config))
        _statsVM = StateObject(wrappedValue: StatsVM(persistence: persistence))
        _membershipVM = StateObject(wrappedValue: MembershipVM())
        _statsVM.wrappedValue.membershipVM = _membershipVM.wrappedValue
        
     }
    
    var body: some View {
        TabView {
            NavigationStack {
            // Lets `RootView` supply navigation via `NavigationStack`,
            //  passing needed viewModels
            // viewModels need to be (and are) injected inside FocusSessionActiveV
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
        .onAppear {
            if !hasInitializedDefaultCategory {
                historyVM.ensureDefaultCategory(userService: userService)
                hasInitializedDefaultCategory = true
                debugPrint("Default category initialized from RootView")
            }
        }
        .environmentObject(statsVM)
        .environmentObject(userService)
        .environmentObject(membershipVM)
    }
}

#Preview {
    RootView()
        .previewTheme()
}
