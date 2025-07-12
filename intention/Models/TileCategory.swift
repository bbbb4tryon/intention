//
//  TileCategory.swift
//  intention
//
//  Created by Benjamin Tryon on 7/12/25.
//

import Foundation
import SwiftUI

struct TileCategory: Identifiable, Codable {
    let id: UUID
    var categoryTitle: String
    var tiles: [String]
}
