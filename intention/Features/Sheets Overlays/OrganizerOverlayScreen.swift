//
//  OrganizerOverlayScreen.swift
//  intention
//
//  Created by Benjamin Tryon on 10/20/25.
//

import SwiftUI

struct OrganizerOverlayScreen: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Binding var categories: [CategoriesModel]
    var onMoveTile: (TileM, UUID, UUID) -> Void
    var onReorder: (_ newTiles: [TileM], _ categoryID: UUID) -> Void
    var onDone: () -> Void
    private var p: ScreenStylePalette { theme.palette(for: .organizer) }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                
                TileOrganizerWrapper(
                    categories: $categories,
                    onMoveTile: onMoveTile,
                    onReorder: onReorder
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 3, y: 1)
                .padding(5)
            } // For when we had a Zstack
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDone() }.font(.body).controlSize(.large)
                    
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button{ dismiss() }
                    label: { Image(systemName: "xmark").imageScale(.small).font(.body).controlSize(.large) }.buttonStyle(.plain).accessibilityLabel("Close")
                }
            }
            // If you *always* want systemGroupedBackground regardless of theme:
            // .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

#Preview {
//    OrganizerOverlayScreen(dismiss: <#T##arg#>, theme: <#T##ThemeManager#>, categories: <#T##[CategoriesModel]#>, onMoveTile: <#T##(TileM, UUID, UUID) -> Void#>, onReorder: <#T##([TileM], UUID) -> Void#>, onDone: <#T##() -> Void#>)
}
