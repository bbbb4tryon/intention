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
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .frame(height: 50)
                .background(palette.background.opacity(0.05))
        }
            if let text = tileText {
                Text(text)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.primary.opacity(0.1))
                    .cornerRadius(8)
            } else {
            
        }
            
    }
}
