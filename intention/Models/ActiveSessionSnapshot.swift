//
//  ActiveSessionSnapshot.swift
//  intention
//
//  Created by Benjamin Tryon on 9/18/25.
//

import SwiftUI

/// Preserve session state (so tiles/timer don’t vanish on relaunch)
//snapshot you save on Begin and clear on completion/cancel
//struct ActiveSessionSnapshot: Codable {
//    var tileTexts: [String]
//    var phase: Phase
//    var chunkIndex: Int                 // 0 or 1
//    var deadline: Int
//}

struct ActiveSessionSnapshot: Codable, Sendable {
    let tileTexts: [String]
    let phase: FocusSessionVM.Phase
    let chunkIndex: Int
    let deadline: Date       // <- single source of truth
}
