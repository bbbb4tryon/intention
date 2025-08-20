//
//  FocusTimerActor.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import Foundation

// Concurrency-Safe focusCountdownTask
// session's start time and the tiles that have been added within that session context
actor FocusTimerActor {
    /// Short debug/UI tests without touching production logic
    private let config: TimerConfig
    init(config: TimerConfig) { self.config = config }
    
    private(set) var sessionStartDate: Date?
    private(set) var currentTiles: [TileM] = [] // NOTE: adding = [] dismisses 'has no initializers'
    
    /// Starts a new session window; clears actor's tile buffer.
    func startSessionTracking() {
        sessionStartDate = Date()
        currentTiles = []           /// Clear tiles for new session
    }
    
    /// Attempts to append a tile; returns false if limit (2) already reached.
    func addTile(_ tile: TileM) -> Bool {
        guard currentTiles.count < 2 else { return false }
        currentTiles.append(tile)
        return true
    }
    
    func shouldCheckIn() -> Bool {
        guard let start = sessionStartDate else { return false }
        return Date().timeIntervalSince(start) >= Double(config.chunkDuration)      /// Should be 1200 - don't hardcode
    }
    
    func resetSessionTracking() {
        sessionStartDate = nil
        currentTiles = []
    }
}
