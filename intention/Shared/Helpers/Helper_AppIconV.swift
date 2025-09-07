//
//  Helper_AppIconV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/5/25.
//

import SwiftUI

// MARK: - AppIconView
struct Helper_AppIconV: View {
    var body: some View {
        //safely unwraps uiimage from bundle extension
        if let uiImage = AppIconProvider.icon {
            // Good: have a non-optional UIImage to create a SwiftUI Image
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit) // maintain aspect ratio
        } else {
            Image(systemName: "app.fill")   // Generic app icon SF Symbol
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.intGreen)
        }
    }
}

#if DEBUG
#Preview {
    Helper_AppIconV()
        .frame(width: 50, height: 50)
        .padding()
}
#endif
