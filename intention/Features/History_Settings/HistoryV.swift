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
            //            Text.pageTitle("History")
            
            Section {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(paddedHistorySlots.indices, id: \.self) { index in
                            TileSlotView(tileText: paddedHistorySlots[index], palette: palette)
                                .frame(maxWidth: .infinity)     // stretch tiles evenly
                        }
                    }
                }
                .padding()
            } header: {
                Text("History")
            }
            footer: {
                Text("Pull to refresh, scroll to review")
            }
            .navigationTitle("History")
            .padding()
            .font(fontTheme.toFont(.title3))    // default body styling
            .foregroundStyle(palette.text)
            .background(palette.background.ignoresSafeArea())
        }
    }
    
    // MARK: - [String?, String?] ->
    //  Extracted computed property, easier for compliler to parse
    private var paddedHistorySlots: [String?] {
        var padded = viewModel.tileHistory.map { Optional($0)}
        while padded.count < viewModel.maxCount {
            padded.append(nil)
        }
        return padded
    }
}

// Mock/ test data prepopulated
#Preview {
    let vm = HistoryVM()
    vm.addToHistory("Mock 1")
    vm.addToHistory("Mock 2")
    return HistoryV(viewModel: vm)
}
/*
 Background: .intMint (or intTan)

 Title text: .intBrown

 Buttons: .intMoss

 Highlight badges: .intSeaGreen
 */
