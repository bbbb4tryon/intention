//
//  TileM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//


import Foundation

// Representative of a single user-created "intention" tile
//  supports JSON encoding
struct TileM: Identifiable, Sendable, Codable {
    let id: UUID
    var text: String
    var timeStamp: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.timeStamp = Date()
    }
}
