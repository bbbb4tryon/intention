//
//  OrganizerOverlayPreviewHost.swift
//  intention
//
//  Created by Benjamin Tryon on 10/26/25.
//
#if DEBUG
import SwiftUI

struct OrganizerOverlayPreviewHost: View {
    @State var cats: [CategoriesModel] = [
        .init(id: UUID(),
              persistedInput: "Work",
              tiles: [TileM(text: "Scope product"), TileM(text: "Follow ups due Wednesday")]
             ),
        .init(id: UUID(),
              persistedInput: "Life",
              tiles: [TileM(text: "Groceries"), TileM(text: "squash")]
             )
    ]
    var body: some View {
        OrganizerOverlayChrome(onClose: {}) {
            OrganizerOverlayScreen(
                categories: $cats,
                onMoveTile: { _,_,_ in },
                onReorder: { _,_ in },
                onDone: {}
            )
        }
    }
}

#Preview {
    PreviewWrapper { OrganizerOverlayPreviewHost().previewTheme() }
}
#endif

#Preview("Organizer Overlay"){
    PreviewWrapper { OrganizerOverlayPreviewHost().previewTheme() }
}
