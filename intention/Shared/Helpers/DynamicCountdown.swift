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
    
    private let screen: ScreenName = .history
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        if isActive {
            ZStack {
                Circle()
                    .fill(p.background.opacity( 0.2))
                
                // Slightly dims pie when paused
                UnwindingPieShape(progress: progress)
                    .fill(p.primary.opacity(fVM.phase == .paused ? 0.4 : 1.0))
                
                VStack(spacing: 4) {
                    T("\(fVM.formattedTime)", .largeTitle)
                        .font(.system(size: digitSize, weight: .bold, design: .monospaced))
                        .foregroundStyle(p.text)
                    
                    if fVM.phase == .paused {
                        T("Paused", .title3)
                            .foregroundStyle(p.textSecondary)
                            .overlay(
                        Circle()
                            .stroke(p.accent, lineWidth: 2)
                            .fill(p.intText.opacity(0.35))
                        )
                    }
                }
            }
            .frame(width: activeSize, height: activeSize)
            .contentShape(Circle())         // tap target matches the circle
            .onTapGesture { handleTap() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(fVM.phase == .paused ? "Resume" : "Pause")
            .accessibilityHint("Tap to \(fVM.phase == .paused ? "resume" : "pause") the countdown")
            .animation(.easeInOut(duration: 0.2), value: progress)
            
        } else if isBetweenChunks {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(p.background.opacity(0.1))
                Text("✓").font(.title).foregroundStyle(p.primary)

            }
            .frame(width: compactSize, height: compactSize)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isBetweenChunks)
        } else {
            EmptyView()             /// Releases vertical space
        }
    }
    private var isActive: Bool {
        fVM.phase == .running ||
        fVM.phase == .paused  ||
        (fVM.phase == .finished && fVM.currentSessionChunk == 2)
    }
    
    private var isBetweenChunks: Bool {
        fVM.phase == .finished && fVM.currentSessionChunk == 1
    }

    private func handleTap() {
        if fVM.phase == .running {
            fVM.performAsyncAction { await fVM.pauseCurrent20MinCountdown() }
        } else if fVM.phase == .paused {
            fVM.performAsyncAction { try await fVM.resumeCurrent20MinCountdown() }
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
