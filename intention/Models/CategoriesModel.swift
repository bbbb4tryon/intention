//
//  Categories.swift
//  intention
//
//  Created by Benjamin Tryon on 7/12/25.
//

import Foundation
import SwiftUI

// MARK: - Inject a known, stable ID
// Updates the initializer with an external ID assignment
struct CategoriesModel: Identifiable, Codable {
    let id: UUID
    var persistedInput: String
    var tiles: [TileM]
    
    init(id: UUID = UUID(), persistedInput: String, tiles: [TileM] = []) {
        self.id = id
        self.persistedInput = persistedInput
        self.tiles = tiles
    }
}
