//
//  FocusTimerActor.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import Foundation

// Concurrency-Safe timer
// Manages session timer logic: 20 min intervals and session windows
actor FocusTimerActor {
    private(set) var sessionStart: Date?
    private(set) var currentTiles: [TileM] = [] // NOTE: adding = [] dismisses 'has no initializers'
    
    func startSession() {
        sessionStart = Date()
        currentTiles = []
    }
    
    func addTile(_ tile: TileM) -> Bool {
        guard currentTiles.count < 2 else { return false }  // Limit per 20 min
        currentTiles.append(tile)
        return true
    }
    
    func shouldCheckIn() -> Bool {
        guard let start = sessionStart else { return false }
        return Date().timeIntervalSince(start) >= 1200      // 20 min
    }
    
    func resetSession() {
        sessionStart = Date()
        currentTiles = []
    }
}
