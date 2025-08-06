//
//  DraggedTile.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import Foundation
import UniformTypeIdentifiers
import CoreTransferable

struct DraggedTile: Codable, Identifiable, Transferable {
    var id: UUID { tile.id }
    let tile: TileM
    let fromCategoryID: UUID
    
    static var transferRepresentation: some TransferRepresentation {
        if #available(iOS 16.0, *) {
               return CodableRepresentation(contentType: .draggableTile)
           } else {
               fatalError("TransferRepresentation only available on iOS 16+")
           }
}

extension UTType {
    static let draggedTile = UTType(exportedAs: "com.intention.draggedtile")
}
