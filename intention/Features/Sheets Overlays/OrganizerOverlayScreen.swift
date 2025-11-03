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
    
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    /* Dark text color */ private let textDarkColor = Color(red: 0.4824, green: 0.3922, blue: 0.1569) // #7B6428
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                // --- Lines 22-32: Apply Material Background and Text Styling ---
                TileOrganizerWrapper(
                    categories: $categories,
                    onMoveTile: onMoveTile,
                    onReorder: onReorder
                )
                .font(.headline)        // Applies to text within the wrapper
                .foregroundStyle(textDarkColor)
                .padding(8)             // Breathing room inside the *material* background
                
                // This replaces .clipShape and .shadow from the original code:
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                // -------------------------------------------------------------)
            }
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                    //                    Button("Done") { onDone() }.font(.body).controlSize(.large)
                
                    Button { onDone() } label: { T("Done", .action) }
                Button { dismiss() } label: { T("Dismiss", .action) }
            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    //                    Button("Done") { onDone() }.font(.body).controlSize(.large)
//                    Button { onDone() } label: { T("Done", .action) }
//                }
//                
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button { dismiss() }
//                    label: { Image(systemName: "xmark")
//                            .imageScale(.small)
//                            .font(.body).foregroundStyle(p.text)
//                            .controlSize(.large)
//                    }
//                    .buttonStyle(.plain).accessibilityLabel("Close")
//                }
//            }
            // .action role renders light text intended for filled buttons;
            // .tint ensures the system buttons and nav items pick up the organizer accent consistently
            .tint(p.accent)
        }
    }
}

#if DEBUG
#Preview("org overlay(dumb)") {
    @State var categories: [CategoriesModel] = []   // empty; no seeded data

    return OrganizerOverlayChrome(onClose: {}) {
        OrganizerOverlayScreen(
            categories: $categories,
            onMoveTile: { _, _, _ in },   // inert
            onReorder:  { _, _ in },      // inert
            onDone: {}
        )
    }
    .environmentObject(ThemeManager())
    .frame(maxWidth: 430)
}
#endif


