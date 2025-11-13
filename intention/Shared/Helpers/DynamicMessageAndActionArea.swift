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
    
    let onRecalibrateNow: () -> Void    // Define sheet closure property, from parent (FocusSessionActiveV) to trigger logic
    
    private let screen: ScreenName = .focus
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    var body: some View {
        VStack(spacing: 16) {
            if focusVM.showRecalibrate {
                T("""
                        Session complete!
                        Time to Rest and Recalibrate Your Mind.
                        """, .title3)
                .foregroundStyle(p.text)
                .multilineTextAlignment(.center)
                
                VStack(spacing: 10) {
                    /// Allow wrapping, or text overflowing doesn't function correctly as a VStack ,not HStack
                    Button { onRecalibrateNow() } label: { T("Recalibrate Now", .action) }
                        .primaryActionStyle(screen: screen)
                    
                    Button { focusVM.performAsyncAction { try await focusVM.beginOverallSession() } }
                    label: { T("Start", .action) }
                        .primaryActionStyle(screen: screen)
                        .primaryActionStyle(screen: screen)
                    
                    Button(role: .destructive) {
                        focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() }
                    } label: { T("End Early", .action) }
                }
            } else if focusVM.currentSessionChunk == 1 && focusVM.phase == .finished {
                T("Done, Continue Your Streak to the Next One?", .title3)
                    .foregroundStyle(p.text)
                    .multilineTextAlignment(.center)
                
                Button { focusVM.performAsyncAction { try await focusVM.beginOverallSession() } }
                label: { T("Start Next", .action) }
                    .primaryActionStyle(screen: screen)
                
                Button(role: .destructive) {
                    focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() }
                } label: { T("End Early", .action) }
                
            } else if focusVM.tiles.count < 2, focusVM.phase == .running {  // if needed
            } else if focusVM.phase == .idle {                           // if needed
            } else if focusVM.phase == .paused {                        // no text needed - handled in DynamicCountdown()
            }
        }
        .padding(.vertical, 8)
    }
}
