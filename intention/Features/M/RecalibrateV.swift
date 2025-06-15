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
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .recalibrate)
        
        VStack(spacing: 24) {
            Text("Recalibrate")
                .styledHeader(font: fontTheme, color: palette.primary)
            
            //            Text(viewModel.instruction)
            Text("viewModel.instruction")
                .styledBody(font: fontTheme, color: palette.text)
            
            //            Text("Time Remaining: \(v.timeRemaing.formatted()) sec")
            Text("Time Remaining")
                .styledBody(font: fontTheme, color: palette.text)
            //
            //            if viewModel.phase == .finished {
            //                Text("Tap Back home")
            //                Text("Tap to post to social")
            //            }
            
            Button("Exit") {
                viewModel.stop()
            }
            .notMainActionStyle()
        }
        .padding()
        .onAppear {
            viewModel.start(mode: theme)
        }
        //        .background(colorTheme.background)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
    }
}

#Preview {
    RecalibrateV()
}
