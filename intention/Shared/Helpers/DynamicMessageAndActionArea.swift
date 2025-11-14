//
//  DynamicMessageAndActionArea.swift
//  intention
//
//  Created by Benjamin Tryon on 6/18/25.
//

import SwiftUI

struct DynamicMessageAndActionArea: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var focusVM: FocusSessionVM
    
    let onRecalibrateNow: () -> Void
    
    private let screen: ScreenName = .focus
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // MARK: Computed helpers
//    private func startSession() {
//        focusVM.performAsyncAction {
//            try await focusVM.beginOverallSession()
//        }
//    }
    // and use Button(action: startSession) { ... }
    
    var body: some View {
        VStack(spacing: 16) {
            if focusVM.showRecalibrate {
                T(
                        """
                        Session complete!
                        Time to Rest and Recalibrate Your Mind.
                        """,
                        .title3
                )
                .foregroundStyle(p.text)
                .multilineTextAlignment(.center)
                
                VStack(spacing: 10) {
                    
                    Button(action: { onRecalibrateNow() }){
                        HStack {
                            Image(systemName: "sparkles")
                            T("Recalibrate Now", .action)
                        }
                    }
                    .primaryActionStyle(screen: screen)
                    
                    Button(action: { focusVM.performAsyncAction { try await focusVM.beginOverallSession() } }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            T("Start", .action)
                        }
                    }
                    .primaryActionStyle(screen: screen)
                    
                    Button(
                        role: .destructive,
                        action: {
                            focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() } }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    T("End Early", .action)
                                }
                            }
                    //                        .secondaryActionStyle(screen: screen)
                    
                }
            } else if focusVM.currentSessionChunk == 1 && focusVM.phase == .finished {
                T("Done, Continue Your Streak to the Next One?", .title3)
                    .foregroundStyle(p.text)
                    .multilineTextAlignment(.center)
                
                Button(
                    action: {
                        focusVM.performAsyncAction { try await focusVM.beginOverallSession() } }) {
                            HStack {
                                Image(systemName: "forward.end.alt.fill")
                                T("Start Next", .action)
                            }
                        }
                    .primaryActionStyle(screen: screen)
                
                Button(
                    role: .destructive,
                    action: {
                        focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() } }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                T("End Early", .action)
                            }
                        }
                
            } else if focusVM.tiles.count < 2, focusVM.phase == .running {  // if needed, intentionally quiet
            } else if focusVM.phase == .idle {                           // if needed, quiet
            } else if focusVM.phase == .paused {                        // no text needed - handled in DynamicCountdown()
            }
        }
        .padding(.vertical, 8)
    }
}
