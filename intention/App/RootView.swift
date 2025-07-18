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

    // ViewModel is the source of truth
    @StateObject private var historyVM = HistoryVM()
    @StateObject private var focusVM = FocusSessionVM()
    @StateObject private var recalibrationVM = RecalibrationVM()
    @StateObject private var statsVM = StatsVM()
    @StateObject private var userService = UserService()
    
    init(){
        // Inject dependency so HistoryV can access tiles from the focusVM
        focusVM.historyVM = historyVM   // see HistoryV, below
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
    }
}

#Preview {
    RootView()
        .previewTheme()
}
