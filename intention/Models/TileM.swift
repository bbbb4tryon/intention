//
//  TileM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import Foundation

// DragPayload: Transferable handles drag and drop
struct TileM: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    var text: String
//    var timeStamp: Date
    
    init(id: UUID = UUID(), text: String) {
//        self.id = UUID()
        self.id = id
        self.text = text
//        self.timeStamp = Date()
    }
}
