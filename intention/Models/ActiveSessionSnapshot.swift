//
//  ActiveSessionSnapshot.swift
//  intention
//
//  Created by Benjamin Tryon on 9/18/25.
//

import SwiftUI

/// Preserve session state (so tiles/timer don’t vanish on relaunch)
//snapshot you save on Begin and clear on completion/cancel
struct ActiveSessionSnapshot: Codable, Sendable {
    var tileTexts: [String]
    var phase: FocusSessionVM.Phase     // .running / .paused / .notStarted
    var chunkIndex: Int                 // 0 or 1
    var remainingSeconds: Int
    var startedAt: Date
}
