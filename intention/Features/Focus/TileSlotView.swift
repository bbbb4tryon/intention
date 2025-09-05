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

    var body: some View {
            let slotBg = (tileText?.isEmpty == false)
                ? palette.card.opacity(0.9)
                : palette.card.opacity(0.35)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(slotBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .frame(height: 50)
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        if diffNoColor && (tileText == nil || tileText?.isEmpty == true) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(palette.border)
                        }
                    }

                if let text = tileText, !text.isEmpty {
                    Text(text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .foregroundStyle(palette.textPrimary)
                        .padding(.horizontal, 8)
                } else {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(palette.accent.opacity(0.6))
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(tileText?.isEmpty == false ? "Intention slot" : "Empty slot")
            .accessibilityHint(tileText?.isEmpty == false ? "" : "Add an intention above, then press Add.")
        }
    }
