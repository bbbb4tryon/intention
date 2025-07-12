//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct HistoryV: View {
    @EnvironmentObject var theme: ThemeManager
    
    @ObservedObject var viewModel: HistoryVM
    
    var body: some View {
        
        let palette = theme.palette(for:.history)

        VStack {
            //        FixedHeaderLayoutV {
            //            Text.pageTitle("History")
            
            Section {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(paddedHistorySlots.indices, id: \.self) { index in
                            TileSlotView(tileText: paddedHistorySlots[index])
                                .environmentObject(theme)
                                .frame(maxWidth: .infinity)     // stretch tiles evenly
                        }
                    }
                }
                .padding()
            }
            footer: {
                Text("Pull to refresh, scroll to review")
            }
            .padding()
            .font(theme.fontTheme.toFont(.title3))    // default body styling
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
        vm.addToHistory("Tile A")
        vm.addToHistory("Tile B")
        vm.addToHistory("Tile C")
        vm.addToHistory("Tile D")

        let theme = ThemeManager()

        return HistoryV(viewModel: vm)
            .environmentObject(theme)
            .previewTheme()
}
/*
 Background: .intMint (or intTan)

 Title text: .intBrown

 Buttons: .intMoss

 Highlight badges: .intSeaGreen
 */
