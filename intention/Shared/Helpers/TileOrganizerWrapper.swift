//
//  TileOrganizerWrapper.swift
//  intention
//
//  Created by Benjamin Tryon on 8/5/25.
//

import SwiftUI

// SwiftUI -> UIKit Bridge
struct TileOrganizerWrapper: UIViewControllerRepresentable {
    @EnvironmentObject var theme: ThemeManager
    
    // --- Local Color Definitions for Overlay ---
    private let textSecondary = Color.intCharcoal.opacity(0.85)
    private let colorDanger = Color.red
    private let colorBorder = Color.intCharcoal
    
    
    @Binding var categories: [CategoriesModel]
    let onMoveTile: (TileM, UUID, UUID) -> Void
    let onReorder: ([TileM], UUID) -> Void
    
    func makeUIViewController(context: Context) -> TileOrganizerVC {
        let vc = TileOrganizerVC()
        vc.onMoveTile = onMoveTile
        vc.onReorder = onReorder    // Hookup for persistence, called in/by HistoryVM
        
        // supply Organizer palette colors to UIKit
        //  - allows SwiftUI to access colors for it (the Overlay)
        
        let p = theme.palette(for: .organizer)
        vc.textColor = UIColor(p.accent)            //FIXME: is .accent correct?
        vc.tileSeparatorColor = UIColor(Color.intTan)   //FIXME: is .intTan correct?
        vc.sectionSeparatorColor = UIColor(colorBorder)
        vc.headerTextColor = UIColor(theme.palette(for: .history).text)
        vc.view.backgroundColor = .clear
        return vc
    }
    
    func updateUIViewController(_ uiViewController: TileOrganizerVC, context: Context) {
        uiViewController.update(categories: categories)
    }
}
