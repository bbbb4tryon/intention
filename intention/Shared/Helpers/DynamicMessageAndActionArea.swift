//
//  DynamicMessageAndActionArea.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

struct DynamicMessageAndActionArea: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: FocusSessionVM
//    let fontTheme: AppFontTheme         // Pass directly, is an AppStorage value
//    let palette: ScreenStylePalette      // Pass directly, is an AppStorage value
    let onRecalibrateNow: () -> Void    // Define sheet closure property, from parent (FocusSessionActiveV) to trigger logic
    
    private let screen: ScreenName = .homeActiveIntentions
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
            var body: some View {
                VStack(spacing: 16) {
                    if viewModel.showRecalibrate {
                        T("Session complete! Ready for recalibration?", .title3)
                            .foregroundStyle(p.text)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button { onRecalibrateNow() } label: { T("Recalibrate Now", .action) }
                                .primaryActionStyle(screen: screen)

                            Button { viewModel.performAsyncAction { try viewModel.startCurrent20MinCountdown() } }
                            label: { T("Start Next Intention", .action) }
                                .primaryActionStyle(screen: screen)

                            Button(role: .destructive) {
                                viewModel.performAsyncAction { await viewModel.resetSessionStateForNewStart() }
                            } label: { T("End Session Early", .label) }
                        }
                    }
                    else if viewModel.currentSessionChunk == 1 && viewModel.phase == .finished {
                        T("First 20 minutes done.\nStart your next intention?", .title3)
                            .foregroundStyle(p.text)
                            .multilineTextAlignment(.center)

                        Button { viewModel.performAsyncAction { try viewModel.startCurrent20MinCountdown() } }
                        label: { T("Start Next Intention", .action) }
                            .primaryActionStyle(screen: screen)

                        Button(role: .destructive) {
                            viewModel.performAsyncAction { await viewModel.resetSessionStateForNewStart() }
                        } label: { T("End Session Early", .label) }
                    }
                    else if viewModel.phase == .running {
                        T("Session in progress…", .body)
                            .foregroundStyle(p.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    else if viewModel.tiles.count < 2 {
                        T("Add your first (or second) intention above", .body)
                            .foregroundStyle(p.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    else if viewModel.phase == .notStarted {
                        T("Press Begin below to start your 20-minute focus.", .caption)
                            .foregroundStyle(p.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 8)
            }
        }

