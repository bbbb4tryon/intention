//
//  CountdownProgress.swift
//  intention
//
//  Created by Benjamin Tryon on 7/10/25.
//

// import SwiftUI
//
//// Extracted for less noise; fontTheme and palette used directly
// struct CountdownProgress: View {
//    let progressFraction: CGFloat
//    let palette: ScreenStylePalette
//    
//    var body: some View {
//        ZStack {
//            // Background circle
//            Circle()
//                .stroke(palette.accent.opacity(0.15), lineWidth: 12)
//                .frame(width: 80, height: 80)
//            
//            // Progress pie foreground
//            Circle()
//                .trim(from: 0.0, to: progressFraction)
//                .stroke(palette.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
//                .rotationEffect(.degrees(-90))
//                .frame(width: 80, height: 80)
//                .animation(.linear(duration: 0.5), value: progressFraction)
//        }
//    }
// }
///// See the computed property `progressFraction` in `FocusSessionActiveV`
