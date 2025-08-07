//
//  TimerConfig.swift
//  intention
//
//  Created by Benjamin Tryon on 8/7/25.
//

import SwiftUI

/// Single source of truth for all durations
///
/// In UI tests, pass a launch argument to flip to short timers
struct TimerConfig {
    let chunkDuration: Int        // 20-min chunks
    let recalibrationDuration: Int // e.g., 4-min

    static let prod = TimerConfig(chunkDuration: 1200, recalibrationDuration: 240)
    static let shortDebug = TimerConfig(chunkDuration: 8, recalibrationDuration: 6)

    // Picks prod unless DEBUG+flag set
    static var current: TimerConfig {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--SHORT_TIMERS") {
            return .shortDebug
        }
        #endif
        return .prod
    }
}
