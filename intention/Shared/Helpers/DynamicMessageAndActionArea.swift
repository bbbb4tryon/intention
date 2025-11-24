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
    private var recalibrateNowLabel: some View {
        HStack {
            Image(systemName: "sparkles")
            T("Recalibrate Now", .action)
        }
    }
    
    private var endEarlyLabel: some View {
        HStack {
            Image(systemName: "xmark.circle")
            T("End Early", .action)
        }
    }
    
    private var isBetweenChunks: Bool {
        focusVM.currentSessionChunk == 1 && focusVM.phase == .finished
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Session complete -> recalibration
            if focusVM.showRecalibrate {
                T("""
                Session complete!
                Time to Rest and Recalibrate Your Mind.
                """,.title3)
                .foregroundStyle(p.text)
                .multilineTextAlignment(.center)
                
                VStack(spacing: 10) {
                    Button(action: onRecalibrateNow ){
                        recalibrateNowLabel
                    }
                    .primaryActionStyle(screen: screen)
                    
                    Button(action: { focusVM.performAsyncAction { try await focusVM.beginOverallSession() } }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            T("Start", .action)
                        }
                    }
                    .primaryActionStyle(screen: screen)
                    
                    Button(role: .destructive, action: {
                        focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() }
                    }) {
                        endEarlyLabel
                    }
                    .secondaryActionStyle(screen: screen)
                }
            } else if isBetweenChunks {
                // text only here, relies on bottom CTA for "Next" button
                T("Done, Continue Your Streak to the Next One?", .title3)
                    .foregroundStyle(p.text)
                    .multilineTextAlignment(.center)
                
            } else if focusVM.tiles.count < 2, focusVM.phase == .running {
                T("Finish adding", .label)
            } else if focusVM.phase == .idle {                           // if needed, hint like "Add next intention above"
            } else if focusVM.phase == .paused {                        // no text needed - handled in DynamicCountdown()
            }
        }
            .padding(.vertical, 8)
    }
}

