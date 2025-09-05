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
    @State private var breathingChoice: Int = 2
    
    // Tunable presets users expect: quick, obvious, one tap.
    private let breathePreset = 60   // 1 min
    private let balancePreset = 30   // 30 sec
    
    var body: some View {
        
        let p = theme.palette(for: .recalibrate)
        ZStack {
            LinearGradient(colors: [p.background, p.background.opacity(0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            Page {
                theme.styledText("Reset & Recalibrate", as: .largeTitle, in: .recalibrate).underline()
                    .foregroundStyle(p.text)
                    .friendlyHelper()
                
                Text("""
                    Short resets help you start your next 20-minute focus chunk fresh.
                     **Choose one below:**
                    """)
                .font(theme.fontTheme.toFont(.footnote))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                
                /// users tap a length first (2/3/4), then “Breathe.”
                if vm.phase == .idle {
                    HStack(spacing: 8) {
                        theme.styledText("Breathing length", as: .caption, in: .recalibrate))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $breathingChoice) {
                            Text("2m").tag(2)
                            Text("3m").tag(3)
                            Text("4m").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }
                    .onChange(of: breathingChoice) { new in
                        do { try vm.setBreathingMinutes(new) }
                        catch { vm.lastError = error }
                    }
                }
                
                /// When inactive, show simple, obvious choices
                if vm.phase != .running {
                    
                    VStack(spacing: 12) {
                        if vm.mode == nil {
                            Button { start(.breathing) } label: {
                                Label {
                                    theme.styledText("Breathe", as: .tile, in: .recalibrate)
                                } icon: {
                                    Image(systemName: RecalibrationMode.breathing.iconName)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .primaryActionStyle(screen: .recalibrate)
                            
                            Button { start(.balancing) } label: {
                                HStack(spacing: 8){
                                    Image(systemName: RecalibrationMode.balancing.iconName)
                                    theme.styledText(activeTitle, as: .tile, in: .recalibrate)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .primaryActionStyle(screen: .recalibrate)
                        }
                    }
                } else {
                    /// Active countdown view: big, legible, tappable cancel
                    VStack(spacing: 16) {
                        Text(activeTitle)
                            .font(.headline)
                        Text(vm.formattedTime)
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Button(role: .destructive) { stop() } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                                .tint(.red)
                        }
                    }
                    .padding(.top, 8)
                }
                // instructions for the selected mode:
                if let m = vm.mode, vm.phase != .running {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(m.instructions, id: \.self) { Text("• \($0)") }
                    }
                    .font(theme.fontTheme.toFont(.footnote))
                    .foregroundStyle(p.text)
                    .padding(.top, 8)
                }
            }
            .task { breathingChoice = vm.currentBreathingMinutes }
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
//            .primaryActionStyle(screen: .recalibrate)
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
//            .secondaryActionStyle(screen: .recalibrate)
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
        RecalibrationV(vm: RecalibrationVM(haptics:NoopHapticsClient()))
            .previewTheme()
    }
}


