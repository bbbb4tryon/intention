//
//  UnwindingPie.swift
//  intention
//
//  Created by Benjamin Tryon on 7/17/25.
//

import SwiftUI

struct UnwindingPieShape: Shape {
    var progress: Double        // from 0.0 to 1.0
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = -90.0
        let endAngle = startAngle - (progress * 360)

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: true
        )
        path.closeSubpath()

        return path
    }
}

//struct Pie: View {
//    @EnvironmentObject var theme: ThemeManager \r private var systemScheme
//    @State private var remainingTime = 60.0
//    let totalTime: TimeInterval = 60.0
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//    
//    var body: some View {
//        let palette = theme.palette(for: .focus
//        ZStack {
//            Circle()
//                .fill(palette.background.opacity(0.2))
//            
//            UnwindingPieShape(progress: remainingTime / totalTime)
//                .fill(palette.accent)
//            
//        }
//        .frame(width: 400, height: 300)
//        .onReceive(timer) { _ in
//            if remainingTime > 0 {
//                remainingTime -= 1
//            }}
//    }
//}
//
//#if DEBUG
//#Preview {
//    Pie()
//        
//}
//#endif
