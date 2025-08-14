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
    
    
    private let activeSize: CGFloat = 200
    private let compactSize: CGFloat = 60
    
    
    var body: some View {
        if isActive {
            ZStack {
                Circle()
                    .fill(palette.background.opacity( 0.2))
                
                UnwindingPieShape(progress: progress)
                    .fill(palette.primary)
                
                Text("\(viewModel.formattedTime)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.text)
            }
            .frame(width: activeSize, height: activeSize)
            .animation(.easeInOut(duration: 0.2), value: progress)
            
        } else if isBetweenChunks {
            ZStack {
                Circle()
                    .fill(palette.background.opacity(0.1))
                Text("✓")
                    .font(.title)
                    .foregroundStyle(palette.primary)
            }
            .frame(width: compactSize, height: compactSize)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isBetweenChunks)
        } else {
            EmptyView()             /// Releases vertical space
        }
    }
    private var isActive: Bool {
        viewModel.phase == .running ||
        (viewModel.phase == .finished && viewModel.currentSessionChunk == 2)
    }
    
    private var isBetweenChunks: Bool {
        viewModel.phase == .finished && viewModel.currentSessionChunk == 1
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
//}

