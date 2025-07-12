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
    @Published var tileHistory: [String] = []
    let maxCount = 24

    // AppStorage wrapper (private, not accessed directly from the view)
    // since `historyVM` is injected into `FocusSessionVM` at startup via `RootView`
    //  the `FocusSessionVM` `func checkSessionCompletion()`'s `addSession(tiles)`
    //  method successfully archives each 2-tile session in and survives app restarts:
    @AppStorage("tileHistoryData") private var tileHistoryData: Data = Data()
    {   didSet  {   loadHistory()    }  }
    
    init() {
        loadHistory()
    }

    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(tileHistory)
            tileHistoryData = encoded
        } catch {
            debugPrint("HistoryVM: Failed to encode history")
        }
    }
    
    private func loadHistory()  {
        guard !tileHistoryData.isEmpty else { return }
        do {
            tileHistory = try JSONDecoder().decode([String].self, from: tileHistoryData)
        } catch {
            debugPrint("HistoryVM: Failed to decode history")
        }
    }
    
    func addToHistory(_ newTile: String){
        tileHistory.insert(newTile, at: 0)  // "capped FIFO" add to top (ascending)
        if tileHistory.count > maxCount {
            tileHistory.removeLast()        // drop oldest if over 24
        }
        saveHistory()                       // saveHistory() is inside addToHistory() to persist automatically
    }


    func clearHistory() {
        tileHistory = []
        tileHistoryData = Data() // clear storage
    }
}
