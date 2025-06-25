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
//            Text.styled("Recalibrate", as: .header, using: fontTheme, in: palette)
            Label("Recalibrate", systemImage: recalibrationChoice.imageName) // image and text
                .font(fontTheme.largeTitle)
                .foregroundStyle(palette.primary)
            
            // Picker
            Picker("Method", selection: $recalibrationChoice) {
                ForEach(RecalibrationTheme.allCases, id: \.self) { theme in
                    Text.styled("\(theme.displayName)", as: .label, using: fontTheme, in: palette)
                            .tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Begin/Start Button
            Button(action: {
                viewModel.start(mode: recalibrationChoice)
            }) {
                Label("Begin", systemImage: "play.circle.fill")
                    .font(.title)
            }
            .mainActionStyle()
            
            // Coundown Displayed
            Text("⏱ \(viewModel.formattedTime)")
                .font(.title2)
                .bold()
                .foregroundStyle(palette.text)
            
            // Instruction List
            ForEach(recalibrationChoice.instruction, id: \.self) { line in
                Text.styled("• \(line)", as: .label, using: fontTheme, in: palette)
            }
            

            // Conditional UI when finished
            if viewModel.phase == .finished {
                Text("✅ Done! Tap to go back")
                    .foregroundColor(palette.text)
                    .padding(.top, 8)
                Text("Tap to post to social")
                    .foregroundStyle(palette.text)
                    .padding(.top, 8)
            }
            
            // Exit Button
            Button("Exit")  {
                viewModel.stop()
            }
            .notMainActionStyle()
        }
        .padding()
        .onAppear {
            viewModel.start(mode: recalibrationChoice)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(palette.background)
                .shadow(color: palette.primary.opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .padding()
    }
}
#Preview {
    RecalibrateV(viewModel: RecalibrationVM())
}

