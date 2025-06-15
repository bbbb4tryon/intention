//
//  TextStyleExtension.swift.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUICore

// Reusable semantic text styles - to use the palette, must pass it in as a parameter!
extension Text {
    static func stylingExtension(_ string: String, palette: ScreenStylePalette) -> some View {
        Text(string)
            .font(.subheadline)
            .foregroundStyle(palette.text)
            .animation(.easeInOut.delay(0.1))
    }
}
