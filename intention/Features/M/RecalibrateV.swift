//
//  RecalibrateV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct RecalibrateV: View {
    @AppStorage("colorTheme") private var colorTheme: AppColorTheme = .default
    @AppStorage("fontTheme") private var fontTheme: AppFontTheme = .serif
    @ObservedObject var viewModel: RecalibrationVM
    @State private var recalibrationChoice: RecalibrationTheme = .breathing
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .recalibrate)
        
        VStack(spacing: 24) {
            Text("Recalibrate")
                .styledHeader(font: fontTheme, color: palette.primary)
            
            Picker("Method", selection: $recalibrationChoice) {
                ForEach(RecalibrationTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            
            Button("Begin Recalibration") {
                viewModel.start(mode: recalibrationChoice)
            }
            .mainActionStyle()
            
//            Text("\(recalibrationChoice.rawValue.capitalized)")
//                .styledTitle(font: fontTheme, color: palette.primary)
            
            ForEach(recalibrationChoice.instruction, id: \.self) { line in
                Text("• \(line)")
                    .styledBody(font: fontTheme, color: palette.text)
            }
            
            Text("Time Remaining: \(viewModel.timeRemaining.formatted()) sec")
                .styledBody(font: fontTheme, color: palette.text)
                .multilineTextAlignment(.center)

            if viewModel.phase == .finished {
                Text("Tap Back home")
                    .styledTitle(font: fontTheme, color: palette.primary)
                Text("Tap to post to social")
                    .styledTitle(font: fontTheme, color: palette.primary)
            }
            
            Button("Exit") {
                viewModel.stop()
            }
            .notMainActionStyle()
        }
        .padding()
        .onAppear {
            viewModel.start(mode: recalibrationChoice)
        }
        .background(palette.background)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
    }
}
#Preview {
    RecalibrateV(viewModel: RecalibrationVM())
}

