//
//  TileOrganizerWrapper.swift
//  intention
//
//  Created by Benjamin Tryon on 8/5/25.
//

import SwiftUI

// SwiftUI -> UIKit Bridge
struct TileOrganizerWrapper: UIViewControllerRepresentable {
    @Binding var categories: [CategoriesModel]
    let onMoveTile: (TileM, UUID, UUID) -> Void
    let onReorder: ([TileM], UUID) -> Void
    
    func makeUIViewController(context: Context) -> TileOrganizerVC {
        let vc = TileOrganizerVC()
        vc.onMoveTile = onMoveTile
        vc.onReorder = onReorder    // Hookup for persistencem, called in/by HistoryVM
        return vc
    }
    
    func updateUIViewController(_ uiViewController: TileOrganizerVC, context: Context) {
        uiViewController.update(categories: categories)
    }
}
