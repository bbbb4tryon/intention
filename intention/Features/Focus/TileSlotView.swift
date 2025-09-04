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
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.accessibilityDifferentiateWithoutColor) private var diffNoColor
    
    // Shows a container, so a Session has 2 slots pre-outlined
    //  “empty” slot look (plus icon or nothing), and once filled, it gets populated.
    var body: some View {
        let p = theme.palette(for: .history)
        let slotBg = (tileText != nil
                      ? p.background.opacity(0.8)
                      : p.background.opacity(0.2))
        
        ZStack {
            /// Using .surface + border from palette
            RoundedRectangle(cornerRadius: 8, style: .continuous)
            //                .strokeBorder(palette.border, lineWidth: 2)
                .fill(slotBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(p.border, lineWidth: 1.0)         /// consistent border
                )
                .frame(height: 50)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            /// dashed outline when “Differentiate Without Color” is enabled
                .overlay {
                    if diffNoColor && tileText == nil {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(p.border)
                    }
                }
            if let text = tileText, !text.isEmpty {
                Text(text)
                    .font(theme.fontTheme.toFont(.body))
                    .foregroundStyle(p.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 8)
            } else {
                /// For the empty state
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(p.accent.opacity(0.55))
                    .accessibilityHidden(true)          /// label provided on container below
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tileText == nil ? "Empty slot" : "Intention slot")
        .accessibilityHint(tileText == nil ? "Add an intention above, then press Add." : "")
    }
}
