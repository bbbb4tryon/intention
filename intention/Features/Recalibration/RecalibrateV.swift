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
        
    @StateObject private var recalibrationVM = RecalibrationVM()
        
    var body: some View {
        
        let palette = colorTheme.colors(for: .recalibrate)
        
        VStack(spacing: 24) {
            // Header
            Text.styled("Recalibrate", as: .header, using: fontTheme, in: palette)
            
            // Picker
            Picker("Method", selection: $recalibrationChoice) {
                ForEach(RecalibrationTheme.allCases, id: \.self) { theme in
                    Text.styled("\(theme.displayName)", as: .label, using: fontTheme, in: palette)
                            .tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Begin Button
            Button(action: {
                viewModel.start(mode: recalibrationChoice)
            }) {
                Text.styled("Begin", as: .action, using: fontTheme, in: palette)
            }
            .mainActionStyle()
            
            // Current Choice Label
            Text.styled(recalibrationChoice.rawValue.capitalized, as: .secondary, using: fontTheme, in: palette)
            
            // Instruction List
            ForEach(recalibrationChoice.instruction, id: \.self) { line in
                Text.styled("• \(line)", as: .label, using: fontTheme, in: palette)
            }
            
            // Coundown Displayed
            Text.styled("Time Remaining: \(viewModel.timeRemaining.formatted()) sec", as: .label, using: fontTheme, in: palette)
                .multilineTextAlignment(.center)

            // Conditional UI when finished
            if viewModel.phase == .finished {
                Text.styled("Tap Back home", as: .secondary, using: fontTheme, in: palette)
                Text.styled("Tap to post to social", as: .secondary, using: fontTheme, in: palette)
            }
            
            // Exit Button
            Button(action: {
                viewModel.stop()
            }) {
                Text("Exit")
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

