//
//  Pie.swift
//  intention
//
//  Created by Benjamin Tryon on 11/3/25.
//
import SwiftUI

struct Pie: View {
    @EnvironmentObject var theme: ThemeManager

    @State private var remainingTime = 60.0
    let totalTime: TimeInterval = 60.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Visual constants
    private let size: CGFloat = 280           // square to avoid oval artifacts
    private let ringWidth: CGFloat = 26       // thick purple strip
    private let digitSize: CGFloat = 96       // giant countdown
    
    var body: some View {
        let palette = theme.palette(for: .focus)
//        ZStack {
//            Circle()
//                .fill(palette.background.opacity(0.2))
//            
//            UnwindingPieShape(progress: remainingTime / totalTime)
//                .fill(palette.accent)
//            
//        }
//        let progress = remainingTime / totalTime
        let progress = max(0, min(1, remainingTime / totalTime))  // 1.0 → 0.0
        ZStack {
            // keeps center empty
            Circle()
//                .stroke(palette.background.opacity(0.15), lineWidth: 26)
                .stroke(palette.background.opacity(0.15), lineWidth: ringWidth)
            
            // actively unwinding ring
            Circle()
//                .trim(from: 0, to: max(0, min(1, progress)))
                .trim(from: 0, to: progress)
                .rotation(.degrees(-90))
//                .stroke(palette.accent, style: StrokeStyle(lineWidth: 26, lineCap: .round))
                .stroke(
                    palette.accent,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round, lineJoin: .round)
                )
            
            // giant countdown in the hole/clear
            Text("\(Int(remainingTime))")
                .font(.system(size: digitSize, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.text)
        }
//        .frame(width: 400, height: 300)
        .frame(width: size, height: size)       // a square
        .animation(.easeInOut(duration: 0.25), value: progress)
        .onReceive(timer) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            }}
    }
}

#if DEBUG
#Preview {
    Pie()
        
}
#endif
