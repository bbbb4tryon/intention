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
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    let title: String
    let count: Int
    let isArchive: Bool
    
    // Only allow edit menu for user categories (not General/Archive).
    var allowEdit: Bool = true
    var onRename: () -> Void
    
    // --- Local Color Definitions for History ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    
    // MARK: - Computed helpers
    
    private var iconName: String? {
        isArchive ? "archivebox.fill" : nil
    }
    
    private var iconTint: Color {
        isArchive ? p.text : p.accent
    }
    
    private var countText: String {
        "\(count)"
    }
    
    private var canEdit: Bool {
        allowEdit
    }
    
    private var accessibilityLabelText: String {
        "\(title), \(count) items"
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            if let iconName {
                Image(systemName: iconName)
                    .imageScale(.small)
                    .foregroundStyle(iconTint)
            }
            
            T(title, .label)
                .lineLimit(2)
            
            Spacer()
            
            Text(countText)
                .font(.callout.monospacedDigit())
                .foregroundStyle(textSecondary)
            
            if canEdit {
                editMenu
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }
    
    // MARK: Edit menu
    
    private var editMenu: some View {
        Menu {
            Button(action: onRename) {
                HStack {
                    Image(systemName: "pencil")
                    T("Rename Category", .action)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "ellipsis.circle")
                T("More", .action)
            }
            .imageScale(.medium)
            .foregroundStyle(p.primary)
        }
    }
}
