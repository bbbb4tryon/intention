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
    
    var body: some View {
        let palette = theme.palette(for: .focus)
        ZStack {
            Circle()
                .fill(palette.background.opacity(0.2))
            
            UnwindingPieShape(progress: remainingTime / totalTime)
                .fill(palette.accent)
            
        }
        .frame(width: 400, height: 300)
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
