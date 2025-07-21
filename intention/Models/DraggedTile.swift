//
//  DraggedTile.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import Foundation

struct DraggedTile: Codable, Identifiable {
    var id: UUID { tile.id }
    let tile: TileM
    let fromCategoryID: UUID
}
