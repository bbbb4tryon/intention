//
//  RecalibrateV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI


struct RecalibrationV: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var vm: RecalibrationVM
    
    // Tunable presets users expect: quick, obvious, one tap.
    private let breathePreset = 60   // 1 min
    private let balancePreset = 30   // 30 sec
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Reset & Recenter")
                    .font(theme.fontTheme.toFont(.title2)).bold()
                
                
                /// When inactive, show simple, obvious choices
                if vm.phase != .running {
                    
                    VStack(spacing: 12) {
                        Button { start(.breathing) } label: {
                            Label("\(label(for: vm.config.breathingDuration)) Breathe",
                                  systemImage: RecalibrationMode.breathing.iconName)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button { start(.balancing) } label: {
                            Label("\(label(for: vm.config.balancingDuration)) Balance",
                                  systemImage: RecalibrationMode.balancing.iconName)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Short resets help you start your next 20-minute focus chunk fresh.")
                        .font(theme.fontTheme.toFont(.footnote))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                    
                } else {
                    
                    /// Active countdown view: big, legible, tappable cancel
                    VStack(spacing: 16) {
                        Text(activeTitle)
                            .font(.headline)
                        
                        Text(formatted(vm.timeRemaining))
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        
                        Button(role: .destructive) { stop() } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .presentationDetents([.height(320), .medium])
            .presentationDragIndicator(.visible)
            
            // Error overlay—same pattern as the rest of the app
            if let err = vm.lastError {
                ErrorOverlay(error: err) { vm.lastError = nil }
                    .zIndex(1)
            }
        }
    }
        
        // MARK: - Private helpers
        
        private var activeTitle: String {
            switch vm.mode {
            case .breathing: return "Breathing"
            case .balancing: return "Balancing"
            case .none: return "Recalibration"
            }
        }
        
        private func formatted(_ seconds: Int) -> String {
            let m = seconds / 60, s = seconds % 60
            return String(format: "%02d:%02d", m, s)
        }
        
        private func start(_ mode: RecalibrationMode) {
            Task {
                do   { try await vm.start(mode: mode) }
                catch {
                    debugPrint("[RecalibrationV.start]", error.localizedDescription)
                    vm.lastError = error
                }
            }
        }

        private func stop() {
            Task {
                do   { try await vm.stop() }
                catch {
                    debugPrint("[RecalibrationV.stop]", error.localizedDescription)
                    vm.lastError = error
                }
            }
        }

        private func label(for seconds: Int) -> String {
            if seconds % 60 == 0 {
                let m = seconds / 60
                return m == 1 ? "1-minute" : "\(m)-minute"
            } else {
                return "\(seconds)s"
            }
        }
}

//struct RecalibrateV: View {
//    @EnvironmentObject var theme: ThemeManager
//    @ObservedObject var viewModel: RecalibrationVM
//    @State private var recalibrationChoice: RecalibrationMode = .breathing
//        
//    @StateObject private var recalibrationVM = RecalibrationVM()
//        
//    var body: some View {
//        
//        let palette = theme.palette(for: .recalibrate)
//        
//        VStack(spacing: 24) {
//            // Header
////            Text.styled("Recalibrate", as: .header, using: fontTheme, in: palette)
//            Label("Recalibrate", systemImage: recalibrationChoice.iconName) // image and text
//                .font(.largeTitle)
//                .foregroundStyle(palette.primary)
//            
//            // Picker
//            Picker("Method", selection: $recalibrationChoice) {
//                ForEach(RecalibrationMode.allCases, id: \.self) { type in
//                    Text("\(type.label)")
//                        .font(.caption)
//                        .tag(type)
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            
//            // Begin/Start Button
//            Button(action: {
//                viewModel.start(mode: recalibrationChoice)
//            }) {
//                Label("Begin", systemImage: "play.circle.fill")
//                    .font(.title)
//            }
//            .mainActionStyle(screen: .recalibrate)
//            .environmentObject(theme)
//            
//            // Coundown Displayed
//            Text("⏱ \(viewModel.formattedTime)")
//                .font(.title2)
//                .bold()
//                .foregroundStyle(palette.text)
//            
//            // Instruction List
//            ForEach(recalibrationChoice.instructions, id: \.self) { line in
//                Text("• \(line)")
//            }
//            
//
//            // Conditional UI when finished
//            if viewModel.phase == .finished {
//                Text("✅ Done! Tap to go back")
//                    .foregroundColor(palette.text)
//                    .padding(.top, 8)
//                Text("Tap to post to social")
//                    .foregroundStyle(palette.text)
//                    .padding(.top, 8)
//            }
//            
//            // Exit Button
//            Button("Exit")  {
//                viewModel.stop()
//            }
//            .notMainActionStyle(screen: .recalibrate)
//            .environmentObject(theme)
//        }
//        .padding()
//        .onAppear {
//            viewModel.start(mode: recalibrationChoice)
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 24)
//                .fill(palette.background)
//                .shadow(color: palette.primary.opacity(0.2), radius: 10, x: 0, y: 4)
//        )
//        .padding()
//    }
//}
#Preview("Recalibrate") {
    PreviewWrapper {
        RecalibrationV(vm: RecalibrationVM(config: .current))
            .previewTheme()
    }
}


