//
//  TileSlotView.swift
//  intention
//
//  Created by Benjamin Tryon on 6/20/25.
//
//
import SwiftUI

struct TileSlotView: View {
    let tileText: String?
    let palette: ScreenStylePalette
    
    // Shows a container, so a Session has 2 slots pre-outlined
    //  “empty” slot look (plus icon or nothing), and once filled, it gets populated.
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(palette.accent, lineWidth: 2)
                .frame(height: 50)
                .background(palette.background.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 8)))
            if let text = tileText {
                Text(text)
                    .font(.body)
                    .foregroundStyle(palette.accent.opacity(0.8))
            } else {
            Image(systemName: "plus")
                    .foregroundStyle(palette.accent.opacity(0.3))
            }
        }            
    }
}
