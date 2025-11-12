//
//  PendingUndoMove.swift
//  intention
//
//  Created by Benjamin Tryon on 11/12/25.
//

import SwiftUI

struct PendingUndoMove: Equatable {
    let tile: TileM
    let fromCategoryID: UUID
    let toCategoryID: UUID
    let expiresAt: Date
}

#Preview {
//    PendingUndoMove()
}
