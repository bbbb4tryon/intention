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
        
        VStack {
            Text("Recalibrate")
                .foregroundStyle(palette.text)
            Section {
                Picker("Options".styledHeader(font: fontTheme, color: palette.text), selection: $recalibrationTheme) {
                    ForEach(RecalibrationTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                            .font(fontTheme.toFont(.body))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(colorTheme.background)
    }
}

#Preview {
    RecalibrateV()
}
