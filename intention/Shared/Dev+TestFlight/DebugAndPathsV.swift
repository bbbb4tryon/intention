//
//  DebugAndPathsV.swift
//  intention
//
//  Created by Benjamin Tryon on 12/3/25.
//
import SwiftUI

/// No theming here on purpose. Plain Apple defaults.
struct DebugAndPathsV: View {
    @EnvironmentObject var historyVM: HistoryVM
    @EnvironmentObject var focusVM: FocusSessionVM
    @EnvironmentObject var recalVM: RecalibrationVM
    @EnvironmentObject var prefs: AppPreferencesVM
    @EnvironmentObject var debug: DebugRouter

    var body: some View {
        NavigationStack {
            List {
                Section("Visibility") {
                    TripleTapOverlay(height: 80) { _ in
                        requirePINThen(expected: "1521") { debug.toggleTab() }
                    }
                    Toggle("Show Debug Tab", isOn: $debug.showTab)
                    Toggle("Short Timers (5s/15s)", isOn: $prefs.debugShortTimers)
                        .onChange(of: prefs.debugShortTimers) { _ in
                            focusVM.applyCurrentTimerConfig()
                        }
                    Button("Hide Tab Now") { debug.showTab = false }
                }

                Section("Focus 5s flow") {
                    Button("Seed 2 Tiles") {
                        Task { @MainActor in
                            focusVM.tileText = "Tile 1"
                            _ = try? await focusVM.handlePrimaryTap(validatedInput: "Tile 1")
                            focusVM.tileText = "Tile 2"
                            _ = try? await focusVM.handlePrimaryTap(validatedInput: "Tile 2")
                        }
                    }
                    Button("Begin 5s Chunk") {
                        Task { try? await focusVM.beginOverallSession() }
                    }
                    Button("Reset Session State") {
                        Task { await focusVM.resetSessionStateForNewStart() }
                    }
                }

                Section("Recalibration 15s") {
                    Button("Show Recalibration Sheet") {
                        focusVM.showRecalibrate = true
                    }
                    Button("Start Breathing (15s)") {
                        recalVM.performAsyncAction {
                            try await recalVM.start(mode: .breathing, duration: TimerConfig.current.recalibrationDuration)
                        }
                    }
                    Button("Start Balancing (15s)") {
                        recalVM.performAsyncAction {
                            try await recalVM.start(mode: .balancing, duration: TimerConfig.current.recalibrationDuration)
                        }
                    }
                    Button("Stop Recalibration") {
                        recalVM.performAsyncAction { try await recalVM.stop() }
                    }
                }

                Section("Errors & Haptics") {
                    Button("Show Sample Error Overlay") {
                        debug.errorTitle = "Debug Sample"
                        debug.errorMessage = "Something went wrong (fake)."
                        debug.showError = true
                    }
                    Button("Haptic: Done Pattern") {
                        let mirror = Mirror(reflecting: focusVM)
                        (mirror.descendant("haptics") as? HapticsClient)?.notifyDone()
                    }
                    Button("Haptic: Added") {
                        let mirror = Mirror(reflecting: focusVM)
                        (mirror.descendant("haptics") as? HapticsClient)?.added()
                    }
                }

                Section("BottomComposer states") {
                    Button("Force Between Chunks (Next)") {
                        focusVM.phase = .finished
                        focusVM.currentSessionChunk = 1
                    }
                }

                Section("History") {
                    Button("New Category") {
                        historyVM.addCategory(persistedInput: "Debug \(Int.random(in: 100...999))")
                    }
                    Button("Move First Tile → Next Category") {
                        guard let src = historyVM.categories.first,
                              historyVM.categories.count > 1,
                              let tile = src.tiles.first else { return }
                        let dest = historyVM.categories[1]
                        historyVM.moveTileWithUndoWindow(tile, fromCategory: src.id, toCategory: dest.id)
                    }
                    Button("Overflow Add (12)") {
                        if let general = historyVM.categories.first {
                            for i in 0..<12 {
                                historyVM.addToHistory(TileM(text: "Overflow \(i)"), to: general.id)
                            }
                        }
                    }
                    Button("Archive First Tile (alert path)") {
                        if let general = historyVM.categories.first,
                           let tile = general.tiles.first {
                            Task { try? await historyVM.moveTileThrowing(tile, fromCategory: general.id, toCategory: historyVM.archiveCategoryID) }
                        }
                    }
                    Button("Rename First User Category") {
                        if historyVM.categories.count > 1 {
                            let id = historyVM.categories[1].id
                            historyVM.renameCategory(id: id, to: "Renamed \(Int.random(in: 10...99))")
                        }
                    }
                }
            }
            .navigationTitle("Debug")
        }
    }
}
