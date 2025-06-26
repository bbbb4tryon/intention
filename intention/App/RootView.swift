//
//  RootView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/19/25.
//

import SwiftUI

struct RootView: View {
//    @EnvironmentObject var theme: ThemeManager
    // ViewModel is the source of truth
    @StateObject private var historyVM = HistoryVM()
    @StateObject private var focusVM = FocusSessionVM()
    @StateObject private var recalibrationVM = RecalibrationVM()
    
    init(){
        // Inject dependency so HistoryV can access tiles from the focusVM
        focusVM.historyVM = historyVM   // see HistoryV, below
    }
    
    var body: some View {
        TabView {
            FocusSessionActiveV(viewModel: focusVM, recalibrationVM: recalibrationVM)
            .tabItem {
                Label("", systemImage: "home.fill")
            }
            HistoryV(viewModel: historyVM)
                .tabItem {
                    Label("", systemImage: "script.fill")
                }
            SettingsV()
                .tabItem {
                    Label("", systemImage: "gear.fill")
                }
        }
    }
}

#Preview {
    RootView()
//        .previewTheme()
}
