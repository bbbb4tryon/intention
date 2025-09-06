//
//  TimerConfig.swift
//  intention
//
//  Created by Benjamin Tryon on 8/7/25.
//

import SwiftUI
import Foundation

/// Single source of truth for all durations
/// In UI tests, pass a launch argument to flip to short timers
struct TimerConfig: Sendable {
    // MARK: Focus/session
    let chunkDuration: Int          /// 20-min chunks (1200)
    
    // MARK: Haptics policy
    struct Haptics: Sendable {
        /// If > 0, fire a light haptic every second when `remaining <= endCountdownStart && remaining > 0`.
        let endCountdownStart: Int       // 3s
        /// If true, haptic once at the halfway point for either mode.
        let halfwayTick: Bool
        /// If > 0 and mode == .balancing, haptic at this interval (seconds) to hint a foot swap.
        let balanceSwapInterval: Int     // 60s
    }
    let haptics: Haptics

    static let prod = TimerConfig(
        chunkDuration: 1200,
        haptics: .init(endCountdownStart: 3, halfwayTick: true, balanceSwapInterval: 60)
    )

    static let shortDebug = TimerConfig(
        chunkDuration: 10,
        haptics: .init(endCountdownStart: 3, halfwayTick: true, balanceSwapInterval: 5)
    )

    // Picks prod unless DEBUG+flag set
    static var current: TimerConfig {
        /// Always short in SwiftUI previews
        if ProcessInfo.processInfo.isSwiftUIPreview {   return .shortDebug    }
        
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--SHORT_TIMERS") { return .shortDebug }
        #endif
        return .prod
    }
}

extension ProcessInfo {
    var isSwiftUIPreview: Bool { environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
}
