//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct HistoryV: View {
    @AppStorage("colorTheme") private var colorTheme: AppColorTheme = .default
    @AppStorage("fontTheme") private var fontTheme: AppFontTheme = .serif
    
    @ObservedObject var viewModel: HistoryVM
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .history)
        
        NavigationView {
//        FixedHeaderLayoutV {
//            Text.pageTitle("Profile")
//        } content: {
            NavigationView {
                List {
                    Section {
                        ForEach(Array(viewModel.sessions.enumerated()), id: \.offset) { index, session in
                            Section("Session: \(index + 1)"){
                                ForEach(session) { tile in
                                    Text(tile.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    } header: {
                        Text("History")
                    }
                    footer: {
                        Text("Pull to refresh, scroll to review")
                    }
                }
            }
        }
        .navigationTitle("History")
        .padding()
        .font(fontTheme.toFont(.title3))    // default body styling
        .foregroundStyle(palette.text)
        .background(palette.background.ignoresSafeArea())
    }
}

// Mock/ test data prepopulated
#Preview {
    let vm = HistoryVM()
    vm.addSession([TileM(text: "Mock 1"), TileM(text: "Mock 2")])
    return HistoryV(viewModel: vm)
}
/*
 Background: .intMint (or intTan)

 Title text: .intBrown

 Buttons: .intMoss

 Highlight badges: .intSeaGreen
 */
