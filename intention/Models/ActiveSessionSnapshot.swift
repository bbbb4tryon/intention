//
//  ActiveSessionSnapshot.swift
//  intention
//
//  Created by Benjamin Tryon on 9/18/25.
//

import SwiftUI

/// Preserve session state (so tiles/timer don’t vanish on relaunch)
struct ActiveSessionSnapshot: Codable, Sendable {
    let tileTexts: [String]
    let phase: FocusVM.Phase
    let chunkIndex: Int
    let deadline: Date       // <- single source of truth
}
