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
        let endCountdownStart: Int       // 3s
        let halfwayTick: Bool
        let balanceSwapInterval: Int     // 60s
    }
    let haptics: Haptics
    
    // sensible default haptics
    init(chunkDuration: Int,
         haptics: Haptics = .init(endCountdownStart: 3, halfwayTick: true, balanceSwapInterval: 60)) {
        self.chunkDuration = chunkDuration
        self.haptics = haptics
    }

    static let prod = TimerConfig(chunkDuration: 20 * 60)
    static let shortDebug = TimerConfig(chunkDuration: 10,
                                        haptics: .init(endCountdownStart: 3, halfwayTick: true, balanceSwapInterval: 5))

    static var current: TimerConfig {
        #if DEBUG
        let override = UserDefaults.standard.integer(forKey: "debug.chunkSeconds")
        return TimerConfig(chunkDuration: override > 0 ? override : 20 * 60)
        #else
        return TimerConfig(chunkDuration: 20 * 60)
        #endif
    }
}
