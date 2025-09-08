//
//  TimerConfig+UITest.swift
//  intention
//
//  Created by Benjamin Tryon on 9/8/25.
//

import Foundation

extension TimerConfig {
    static let fastUITest = TimerConfig(
    chunkDuration: 3,
        haptics: .init(endCountdownStart: 1, halfwayTick: false, balanceSwapInterval: 1)
    )
}
