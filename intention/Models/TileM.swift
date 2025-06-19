//
//  TileM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//


import Foundation

// Representative of a single user-created "intention" tile
struct TileM: Identifiable, Sendable {
    // FIXME: LET instead of VAR?
    let id: UUID = UUID()
    var text: String
    var timeStamp: Date = Date()
}
