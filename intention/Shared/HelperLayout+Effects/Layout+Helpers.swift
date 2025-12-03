//
//  Layout+Helpers.swift
//  intention
//
//  Created by Benjamin Tryon on 8/27/25.
//

import SwiftUI
/// Only the Page applies horizontal padding. Children don’t.
/// Add to any top-level screen container (ScrollView or VStack)
struct Page<Content: View>: View {
    let top: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content
    init(top: CGFloat = 8,
         alignment: HorizontalAlignment = .leading,
         @ViewBuilder _ content: @escaping () -> Content) {
        self.top = top; self.alignment = alignment; self.content = content
    }
    var body: some View {
        /// One horizontal margin to rule them all
        VStack(alignment: alignment, spacing: 16, content: content)
            .padding(.horizontal, 16)
            .padding(.top, 8)                       /// Small top; adjust per screen
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}/// Card section with consistent look for Settings, History blocks
struct Card<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder _ content: @escaping () -> Content) { self.content = content }
    var body: some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Bottom toast that clears tab bar safely on all devices
struct BottomToast<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder _ content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(radius: 2, y: 1)
    }
}

struct TileCell: View {
    let tile: TileM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tile.text).font(.callout)
        }
        .padding(12)
//        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
    }
}
