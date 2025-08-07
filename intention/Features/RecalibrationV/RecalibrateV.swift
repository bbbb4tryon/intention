//
//  RecalibrateV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct RecalibrateV: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: RecalibrationVM
    @State private var recalibrationChoice: RecalibrationType = .breathing
        
    @StateObject private var recalibrationVM = RecalibrationVM()
        
    var body: some View {
        
        let palette = theme.palette(for: .recalibrate)
        
        VStack(spacing: 24) {
            // Header
//            Text.styled("Recalibrate", as: .header, using: fontTheme, in: palette)
            Label("Recalibrate", systemImage: recalibrationChoice.iconName) // image and text
                .font(.largeTitle)
                .foregroundStyle(palette.primary)
            
            // Picker
            Picker("Method", selection: $recalibrationChoice) {
                ForEach(RecalibrationType.allCases, id: \.self) { type in
                    Text("\(type.label)")
                        .font(.caption)
                        .tag(type)
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
            .mainActionStyle(screen: .recalibrate)
            .environmentObject(theme)
            
            // Coundown Displayed
            Text("⏱ \(viewModel.formattedTime)")
                .font(.title2)
                .bold()
                .foregroundStyle(palette.text)
            
            // Instruction List
            ForEach(recalibrationChoice.instructions, id: \.self) { line in
                Text("• \(line)")
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
            .notMainActionStyle(screen: .recalibrate)
            .environmentObject(theme)
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
#Preview("Recalibrate") {
    PreviewWrapper {
        RecalibrateV(viewModel: RecalibrationVM())
    }
}


