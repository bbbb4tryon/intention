//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

struct RootView: View {
    // ViewModel is the source of truth
    @StateObject private var historyVM = HistoryVM()
    @StateObject private var focusVM = FocusSessionVM()
    @StateObject private var recalibrationVM = RecalibrationVM()
    @StateObject private var statsVM = StatsVM()
    
    init(){
        // Inject dependency so HistoryV can access tiles from the focusVM
        focusVM.historyVM = historyVM   // see HistoryV, below
    }
    
    var body: some View {
        TabView {
            // Lets `RootView` supply navigation via `NavigationStack`
            NavigationStack {
                FocusSessionActiveV(viewModel: focusVM, recalibrationVM: recalibrationVM)
                    .navigationTitle("Focus")
            }
            .tabItem {
                Image(systemName: "house.fill")
            }
            NavigationStack {
                HistoryV(viewModel: historyVM)
                    .navigationTitle("History")
            }
            .tabItem {
                Image(systemName: "book.fill")
            }
            NavigationStack {
                SettingsV(viewModel: statsVM)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
            }
        }
    }
}

#Preview {
    RootView()
        .previewTheme()
}
