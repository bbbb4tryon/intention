//
//  DynamicCountdown.swift
//  intention
//
//  Created by Benjamin Tryon on 8/13/25.
//

import SwiftUI

struct DynamicCountdown: View {
    @ObservedObject var viewModel: FocusSessionVM
    let palette: ScreenStylePalette
    
    /// Current progress size (0.0 to 1.0), passed from FocusSessionActiveV
    let progress: CGFloat
    
    var body: some View {
        Group {
            if shouldShowFullTimer {
                ZStack {
                    Circle()
                        .fill(palette.background.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    UnwindingPieShape(progress: progress)
                        .fill(palette.primary)
                        .frame(width: 200, height: 200)
                    
                    Text("\(viewModel.formattedTime)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .id("countdownTimer")
                        .transition(.opacity)
                        .foregroundStyle(palette.text)
                }
                .animation(.easeInOut(duration: 0.2), value: progress)
            } else if shouldShowCompactCheckmark {
                ZStack {
                    Circle()
                        .fill(palette.background.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text("✓")
                        .font(.title)
                        .foregroundStyle(palette.primary)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: progress)
            }
        }
    }
    private var shouldShowFullTimer: Bool {
        viewModel.phase == .running ||
        (viewModel.phase == .finished && viewModel.currentSessionChunk == 2)
    }
    
    private var shouldShowCompactCheckmark: Bool {
        viewModel.phase == .finished && viewModel.currentSessionChunk == 1
    }
}

