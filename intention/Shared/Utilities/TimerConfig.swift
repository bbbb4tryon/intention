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
    static let shortDebug = TimerConfig(chunkDuration: 10, recalibrationDuration: 20)

    // Picks prod unless DEBUG+flag set
    static var current: TimerConfig {
        /// Always short in SwiftUI previews
        if ProcessInfo.processInfo.isSwiftUIPreview {   return .shortDebug    }
        
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--SHORT_TIMERS") {
            return .shortDebug
        }
        #endif
        return .prod
    }
}

extension ProcessInfo {
    var isSwiftUIPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
