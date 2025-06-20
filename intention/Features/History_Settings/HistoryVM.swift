//
//  HistoryVM.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//


import Foundation
import SwiftUI

@MainActor
final class HistoryVM: ObservableObject {
    @Published var sessions: [[TileM]] = []

    // AppStorage wrapper (private, not accessed directly from the view)
    // since `historyVM` is injected into `FocusSessionVM` at startup via `RootView`
    //  the `FocusSessionVM` `func checkSessionCompletion()`'s `addSession(tiles)` method successfully archives each 2-tile session in:
    @AppStorage("tileHistoryData") private var tileHistoryData: Data = Data()

    init() {
        loadHistory()
    }

    func addSession(_ tiles: [TileM]) {
        guard !tiles.isEmpty else { return }
        sessions.append(tiles)
        saveHistory()
    }

    func clearHistory() {
        sessions = []
        tileHistoryData = Data() // clear storage
    }

    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(sessions)
            tileHistoryData = encoded
        } catch {
            print("Failed to encode session history: \(error)")
        }
    }

    private func loadHistory() {
        guard !tileHistoryData.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([[TileM]].self, from: tileHistoryData)
            sessions = decoded
        } catch {
            print("Failed to decode session history: \(error)")
        }
    }
}
