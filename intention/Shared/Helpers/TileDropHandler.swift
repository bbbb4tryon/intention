//
//  TileDropHandler.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import Foundation
import UniformTypeIdentifiers

actor TileDropHandler {
    func handleDrop(providers: [NSItemProvider]) async -> DraggedTile? {
        for provider in providers {
            if let dragged = try? await provider.loadTransferable(type: DraggedTile.self) {
                return dragged
            }
        }
        return nil
    }
}
