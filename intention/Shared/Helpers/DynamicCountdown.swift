//
//  DynamicCountdown.swift
//  intention
//
//  Created by Benjamin Tryon on 8/13/25.
//

import SwiftUI

struct DynamicCountdown: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var fVM: FocusSessionVM
    let palette: ScreenStylePalette
    
    /// Current progress sizes (0.0 to 1.0), passed from FocusSessionActiveV
    let progress: CGFloat
    private let activeSize: CGFloat = 150
    private let compactSize: CGFloat = 60
    let digitSize: CGFloat = 48
    
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
    
    var body: some View {
        if isActive {
            ZStack {
                // Background circle
                Circle()
                    .fill(palette.background.opacity( 0.2))     // Use opacity(0.2) or Color.clear here, the dimmed effect is applied below
                
                // Pause overlay -- appears last, on top of everything
                if fVM.phase == .paused {
                    // PAUSED STATE
                    ZStack {
                        // The translucent opaque background for the pause state
                        Circle().fill(Color.black.opacity(0.35))     // Uses black for a better opaque look
                        
                        VStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(palette.accent)
                                .shadow(radius: 2)
                            
                            T("Paused", .title3)
                                .foregroundStyle(palette.text)
                                .fontWeight(.bold)
                        }
                    }
                    .clipShape(Circle())                        // Clips ZStack to the circle area so it doesn't cover surrounding content
                    .transition(.opacity)
                } else {
                    // RUNNING/ACTIVE STATE
                    // Pie slicing
                    UnwindingPieShape(progress: progress)
                        .fill(palette.primary)
                    //                    .fill(palette.primary.opacity(fVM.phase == .paused ? 0.4 : 1.0))
                    
                    // Time text in the center - always present, but lower Z-index than the pause overlay
                    VStack(spacing: 4) {
                        let digits = T("\(fVM.formattedTime)", .largeTitle)
                            .font(.system(size: digitSize, weight: .bold, design: .monospaced))
                        
                        // Main fill color
                        digits
                            .foregroundStyle(palette.text)
                        // Soft outline intText(F5F5F5)
                            .overlay(
                                ZStack {
                                    digits.foregroundStyle(Color.intText).offset(x:  0.75, y:  0.75)
                                    digits.foregroundStyle(Color.intText).offset(x: -0.75, y:  0.75)
                                    digits.foregroundStyle(Color.intText).offset(x:  0.75, y: -0.75)
                                    digits.foregroundStyle(Color.intText).offset(x: -0.75, y: -0.75)
                                }
                            )
                        // Drop shadow for depth
                            .shadow(color: .black.opacity(0.20), radius: 2, x: 0, y: 1)
                    }
                    //                .opacity(fVM.phase == .paused ? 0.2 : 1.0)      // Modifier to dim the time text when paused
                    
                    // add a subtle transition
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
                //                Text("✓").font(.largeTitle).foregroundStyle(palette.primary)
                
            }
            .frame(width: compactSize, height: compactSize)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isBetweenChunks)
        } else if isBothChunksDone {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(palette.background.opacity(0.1))
                //                Text("✓").font(.largeTitle).foregroundStyle(palette.primary)
            }
            .frame(width: compactSize, height: compactSize)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isBothChunksDone)
        } else {
            EmptyView()             /// Releases vertical space
        }
    }
}
//
//    var body: some View {
//
//
//        Group {
//            if shouldShowFullTimer {
//                ZStack {
//                    Circle()
//                        .fill(palette.background.opacity(0.2))
//                        .frame(width: 200, height: 200)
//
//                    UnwindingPieShape(progress: progress)
//                        .fill(palette.primary)
//
//                    Text("\(viewModel.formattedTime)")
//                        .font(.system(size: 48, weight: .bold, design: .monospaced))
//                        .id("countdownTimer")
//                        .transition(.opacity)
//                        .foregroundStyle(palette.text)
//                }
//                .animation(.easeInOut(duration: 0.2), value: progress)
//            } else if shouldShowCompactCheckmark {
//                ZStack {
//                    Circle()
//                        .fill(palette.background.opacity(0.1))
//                        .frame(width: 60, height: 60)
//
//                    Text("✓")
//                        .font(.title)
//                        .foregroundStyle(palette.primary)
//                }
//                .transition(.opacity)
//                .animation(.easeInOut(duration: 0.2), value: progress)
//            }
//        }
//    }
//    private var shouldShowFullTimer: Bool {
//        viewModel.phase == .running ||
//        (viewModel.phase == .finished && viewModel.currentSessionChunk == 2)
//    }
//
//    private var shouldShowCompactCheckmark: Bool {
//        viewModel.phase == .finished && viewModel.currentSessionChunk == 1
//    }
// }
