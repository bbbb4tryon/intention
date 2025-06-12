//
//  FocusSessionVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

// ViewModel talks to FocusTimerActor and drives the UI

enum FocusSessionError: Error {
    case emptyInput
    case tooManyTiles
}

@MainActor
final class FocusSessionVM: ObservableObject {
    @Published var tileText: String = ""
    @Published var tiles: [TileM] = []
    @Published var canAdd: Bool = true
    @Published var sessionActive: Bool = false
    
    private let timer = FocusTimerActor()
    
    func startSession() async {
        await timer.startSession()
        sessionActive = true
    }
    
    func submitTile() async {
        let trimmed = tileText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let tile = TileM(text: trimmed)
        let success = await timer.addTile(tile)     //NOTE: - Initialization of immutable value 'success' was never used; consider replacing with assignment to '_' or removing it... is Dismissed by adding if conditions below
        
        if success {
            tiles.append(tile)
            tileText = ""
            canAdd = tiles.count < 2
        }
    }
}
