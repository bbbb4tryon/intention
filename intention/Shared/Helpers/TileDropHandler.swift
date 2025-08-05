//
//  TileDropHandler.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

actor TileDropHandler {
    func handleDrop(providers: [NSItemProvider]) async -> DraggedTile? {
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) else { continue }
            
                do {
                    let data = try await withCheckedThrowingContinuation { continuation in
                        provider.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, error in
                        }
                    
                   if let dragged = try? JSONDecoder().decode(DraggedTile.self, from: data) {
                        return dragged
                    } catch {
                        debugPrint("[TileDropHandler] error")
                    }
                }
                return nil
            }
        }
    }
}
