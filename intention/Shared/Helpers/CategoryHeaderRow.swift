//
//  CategoryHeaderRow.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//
//
import SwiftUI

struct CategoryHeaderRow: View {
    @EnvironmentObject var theme: ThemeManager
    
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    let title: String
    let count: Int
    let isArchive: Bool
    
    /// Only allow edit menu for user categories (not General/Archive).
    var allowEdit: Bool = true
    var onRename: () -> Void
    var onDelete: () -> Void
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isArchive ? "archivebox.fill" : "")
                .imageScale(.small)
                .foregroundStyle(isArchive ? p.text : p.accent)
            
            T("\(title)", .label)
                .lineLimit(2)
            
            Spacer()
            
            Text("\(count)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(textSecondary)
            
            if allowEdit {
                Menu {
                    Button("Rename", action: onRename).padding()
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(p.primary)
                        .imageScale(.medium)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(count) items")
    }
}
