//
//  TextStyleExtension.swift.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUICore

// Reusable semantic text styles
extension Text {
    static func stylingExtension(_ string: String) -> some View {
        Text(string)
            .font(.subheadline)
            .foregroundStyle(.intBrown)
            .animation(
                .easeInOut.delay(0.1)
            )
    }
}
