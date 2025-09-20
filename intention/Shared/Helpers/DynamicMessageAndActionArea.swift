//
//  DynamicMessageAndActionArea.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

struct DynamicMessageAndActionArea: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var focusVM: FocusSessionVM
//    let fontTheme: AppFontTheme       // Pass directly, is an AppStorage value
//    let palette: ScreenStylePalette   // Pass directly, is an AppStorage value
    let onRecalibrateNow: () -> Void    // Define sheet closure property, from parent (FocusSessionActiveV) to trigger logic
    
    private let screen: ScreenName = .homeActiveIntentions
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
//    init(focusVM: FocusSessionVM,
//         onRecalibrateNow: @escaping () -> Void) {
//        self._focusVM = ObservedObject(initialValue: focusVM)
//        self.onRecalibrateNow = onRecalibrateNow
//    }
            var body: some View {
                VStack(spacing: 16) {
                    if focusVM.showRecalibrate {
                        T("Session complete! Ready for recalibration?", .title3)
                            .foregroundStyle(p.text)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 10) {
                            /// Allow wrapping, or text overflowing doesn't function correctly as a VStack ,not HStack
                            Button { onRecalibrateNow() } label: { T("Recalibrate Now", .action) }
                                .primaryActionStyle(screen: screen)

                            Button { focusVM.performAsyncAction { try focusVM.startCurrent20MinCountdown() } }
                            label: { T("Start Next Intention", .action) }
                                .primaryActionStyle(screen: screen)

                            Button(role: .destructive) {
                                focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() }
                            } label: { T("End Session Early", .label) }
                        }
                    } else if focusVM.currentSessionChunk == 1 && focusVM.phase == .finished {
                        T("First 20 minutes done.\nStart your next intention?", .title3)
                            .foregroundStyle(p.text)
                            .multilineTextAlignment(.center)

                        Button { focusVM.performAsyncAction { try focusVM.startCurrent20MinCountdown() } }
                        label: { T("Start Next Intention", .action) }
                            .primaryActionStyle(screen: screen)

                        Button(role: .destructive) {
                            focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() }
                        } label: { T("End Session Early", .label) }
                    } else if focusVM.phase == .running {
//                        T("Session in progress…", .body)
//                            .foregroundStyle(p.textSecondary)
//                            .multilineTextAlignment(.center)
                    } else if focusVM.tiles.count < 2 {
                        T("Add your first (or second) intention above", .body)
                            .foregroundStyle(p.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if focusVM.phase == .idle {
                        T("Press Begin below to start your 20-minute focus.", .caption)
                            .foregroundStyle(p.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if focusVM.phase == .paused {
                        T("Paused", .caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
