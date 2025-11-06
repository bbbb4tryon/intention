//
//  DynamicCountdown.swift
//  intention
//
//  Created by Benjamin Tryon on 8/13/25.
//

import SwiftUI

struct DynamicCountdown: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var fVM: FocusSessionVM
    let palette: ScreenStylePalette
    
    /// Current progress sizes (0.0 to 1.0), passed from FocusSessionActiveV
    let progress: CGFloat
    private let activeSize: CGFloat = 280       // was 220
    private let compactSize: CGFloat = 72       // was 60
    let digitSize: CGFloat = 44                 // small so circle/pause feel larger
    
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: .focus) }
    }
    
    private var isActive: Bool {
        fVM.phase == .running ||
        fVM.phase == .paused  ||
        (fVM.phase == .finished && fVM.currentSessionChunk == 2)
    }
    
    private var isBetweenChunks: Bool {
        let oneDone = fVM.phase == .finished && fVM.currentSessionChunk == 1
        return oneDone
    }
    
    private var isBothChunksDone : Bool {
        let oneDone = fVM.phase == .finished && fVM.currentSessionChunk == 1
        let twoDone = fVM.phase == .finished && fVM.currentSessionChunk == 2
        return oneDone && twoDone
    }
    
    private func handleTap() {
        if fVM.phase == .running {
            fVM.performAsyncAction { await fVM.pauseCurrent20MinCountdown() }
        } else if fVM.phase == .paused {
            fVM.performAsyncAction { try await fVM.resumeCurrent20MinCountdown() }
        }
    }
    
    // --- Local Color Definitions for the Pie and Countdown ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    // MARK: Countdown Label (digits with outline + shadow)
    private var countdownLabel: some View {
        // Base styled text from ThemeManager (role: .label)
        let base = T(fVM.formattedTime, .label)
        
        // Apply the monospaced, large font *once*
        let styled = base
            .font(.system(size: digitSize, weight: .bold, design: .monospaced))
        
        // Main “visible” layer
        let mainLayer = styled
            .foregroundStyle(palette.text)
        
        // Soft pseudo-outline by drawing the same text 4x slightly offset
        let outlineLayer = ZStack {
            // or styled.foregroundStyle(Color.defaultUtilityGray?).offset(x:  0.75, y:  0.75)
            styled.foregroundStyle(Color.intText).offset(x:  0.75, y:  0.75)
            styled.foregroundStyle(Color.intText).offset(x: -0.75, y:  0.75)
            styled.foregroundStyle(Color.intText).offset(x:  0.75, y: -0.75)
            styled.foregroundStyle(Color.intText).offset(x: -0.75, y: -0.75)
        }
        
        return mainLayer
            .overlay(outlineLayer)
            .shadow(color: .black.opacity(0.20), radius: 2, x: 0, y: 1)
    }

    var body: some View {
        if isActive {
            ZStack {
                // Background circle
                Circle()
                // Use opacity(0.2) or Color.clear here, the dimmed effect is applied below
                    .fill(palette.background.opacity( 0.2))
                
                // Pause overlay -- appears last, on top of everything
                if fVM.phase == .paused {
                    // PAUSED STATE
                    ZStack {
                        // The translucent opaque background for the pause state
                        Circle().fill(Color.black.opacity(0.35))     // Uses black for a better opaque look
                        
                        VStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)       // was 40 x 40
                                .foregroundStyle(palette.accent)
                                .shadow(radius: 2)
                            
                            T("Paused", .title3)
                                .foregroundStyle(palette.text)
                                .fontWeight(.bold)
                        }
                    }
                    .clipShape(Circle())                        // Clips ZStack to circle here
                    .transition(.opacity)
                } else {
                    // RUNNING/ACTIVE STATE
                    
                    // Pie slicing
                    UnwindingPieShape(progress: progress)
                        .fill(palette.accent)
                    
                    
                    // Time text in the center
                    countdownLabel
                    // optional dim when paused; here it's only active/running so keep full
                        .opacity(fVM.phase == .paused ? 0.3 : 1.0)
                }
            }
            .frame(width: activeSize, height: activeSize)
            .contentShape(Circle())                             // tap target matches the circle
            .onTapGesture { handleTap() }                       // Keep as-is: the tap target persists across both `paused` and `running`, applies to entire ZStack, which is what is wanted
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(fVM.phase == .paused ? "Resume" : "Pause")
            .accessibilityHint("Tap to \(fVM.phase == .paused ? "resume" : "pause") the countdown")
            .animation(.easeInOut(duration: 0.2), value: progress)
            
        } else if isBetweenChunks {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(palette.background.opacity(0.1))
                // Text("✓").font(.largeTitle).foregroundStyle(palette.primary)
                
            }
            .frame(width: compactSize, height: compactSize)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isBetweenChunks)
            
        } else if isBothChunksDone {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(palette.background.opacity(0.1))
                // Text("✓").font(.largeTitle).foregroundStyle(palette.primary)
            }
            .frame(width: compactSize, height: compactSize)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isBothChunksDone)
        } else {
            EmptyView()             /// Releases vertical space
        }
    }
}
