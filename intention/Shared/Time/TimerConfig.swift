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
struct TimerConfig: Sendable {  // <--- needs Equatable, too?
    // MARK: Focus/session
    let chunkDuration: Int          // 20-min chunks (1200) - focus chunks
    let recalibrationDuration: Int  // breathing/balancing seconds
    
    // MARK: Haptics policy
    struct Haptics: Sendable {
        let endCountdownStart: Int       // 3s
        let halfwayTick: Bool
        let balanceSwapInterval: Int     // 60s
    }
    let haptics: Haptics
    
    // sensible default haptics
    init(
        chunkDuration: Int,
        recalibrationDuration: Int,
        haptics: Haptics = .init(endCountdownStart: 3, halfwayTick: true, balanceSwapInterval: 60)
    ){
        self.chunkDuration = chunkDuration
        self.recalibrationDuration = recalibrationDuration
        self.haptics = haptics
    }

    static let prod = TimerConfig(chunkDuration: (20 * 60), recalibrationDuration: (2 * 60))
    static let debug = TimerConfig(chunkDuration: 5, recalibrationDuration: 15)
    
    static var current: TimerConfig {
        if BuildInfo.isDebugOrTestFlight && UserDefaults.standard.bool(forKey: "debugShortTimers") {
            return .debug
        } else {
            return .prod
        }
    }
    

}
