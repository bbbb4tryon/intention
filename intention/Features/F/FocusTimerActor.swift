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
    private(set) var sessionStartDate: Date?
    private(set) var currentTiles: [TileM] = [] // NOTE: adding = [] dismisses 'has no initializers'
    
    func startSessionTracking() {
        sessionStartDate = Date()
        currentTiles = []       // Clear tiles for new session
    }
    
    func addTile(_ tile: TileM) -> Bool {
        guard currentTiles.count < 2 else {
            print("Sessions have 2 task limit //focusTimerActor")
            return false
        }
        currentTiles.append(tile)
        return true
    }
    
    func shouldCheckIn() -> Bool {
        guard let start = sessionStartDate else { return false }
        return Date().timeIntervalSince(start) >= 1200      // 20 min
    }
    
    func resetSessionTracking() {
        sessionStartDate = nil
        currentTiles = []
    }
}
