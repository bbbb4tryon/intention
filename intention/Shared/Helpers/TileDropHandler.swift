//
//  TileDropHandler.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import Foundation

actor TileDropHandler {
    func handleDrop(providers: [NSItemProvider]) async -> DraggedTile? {
        for provider in providers {
            let data = try await provider.loadDataRepresentation(forTypeIdentifier: "public.data")

               let dragged = try? JSONDecoder().decode(DraggedTile.self, from: data) {
                return dragged
            }
        }
        return nil
    }
}
