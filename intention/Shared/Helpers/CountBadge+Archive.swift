//
//  CountBadge+Archive.swift
//  intention
//
//  Created by Benjamin Tryon on 8/14/25.
//

import SwiftUI

struct CountBadge_Archive: View {
    let fontTheme: AppFontTheme
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(fontTheme.toFont(.caption2))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}
