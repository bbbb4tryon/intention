//
//  RecalibrateV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

//
//struct RecalibrationV: View {
//    @ObservedObject var vm: RecalibrationVM
//
//    // Tunable presets users expect: quick, obvious, one tap.
//    private let breathePreset = 60   // 1 min
//    private let balancePreset = 30   // 30 sec
//
//    var body: some View {
//        ZStack {
//            VStack(spacing: 20) {
//                Text("Reset & Recenter")
//                    .font(.title2).bold()
//
//                // When inactive, show simple, obvious choices
//                if !vm.isActive {
//                    VStack(spacing: 12) {
//                        Button {
//                            Task {
//                                do   { try await vm.begin(.breathe(seconds: breathePreset)) }
//                                catch {
//                                    debugPrint("[RecalibrationV.begin.breathe] \(error)")
//                                    vm.lastError = error
//                                }
//                            }
//                        } label: {
//                            Label("1-minute Breathe", systemImage: "wind")
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.borderedProminent)
//
//                        Button {
//                            Task {
//                                do   { try await vm.begin(.balance(seconds: balancePreset)) }
//                                catch {
//                                    debugPrint("[RecalibrationV.begin.balance] \(error)")
//                                    vm.lastError = error
//                                }
//                            }
//                        } label: {
//                            Label("30-sec Balance", systemImage: "figure.walk")
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.bordered)
//                    }
//
//                    Text("Short resets help you start your next 20-minute focus chunk fresh.")
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
//                        .multilineTextAlignment(.center)
//                        .padding(.top, 4)
//
//                } else {
//                    // Active countdown view: big, legible, tappable cancel
//                    VStack(spacing: 16) {
//                        Text(activeTitle)
//                            .font(.headline)
//
//                        Text(formatted(vm.secondsRemaining))
//                            .font(.system(size: 56, weight: .semibold, design: .rounded))
//                            .monospacedDigit()
//
//                        Button(role: .destructive) {
//                            Task {
//                                do   { try await vm.cancel() }
//                                catch {
//                                    debugPrint("[RecalibrationV.cancel] \(error)")
//                                    vm.lastError = error
//                                }
//                            }
//                        } label: {
//                            Label("Cancel", systemImage: "xmark.circle")
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.bordered)
//                    }
//                    .padding(.top, 8)
//                }
//            }
//            .padding()
//            .presentationDetents([.height(320), .medium])
//            .presentationDragIndicator(.visible)
//
//            // Error overlay—same pattern as the rest of the app
//            if let e = vm.lastError {
//                ErrorOverlay(error: e) { vm.lastError = nil }
//                    .zIndex(1)
//            }
//        }
//    }
//
//    private var activeTitle: String {
//        switch vm.currentType {
//        case .breathe: return "Breathe"
//        case .balance: return "Balance"
//        case .none: return "Recalibration"
//        }
//    }
//
//    private func formatted(_ seconds: Int) -> String {
//        let m = seconds / 60, s = seconds % 60
//        return String(format: "%02d:%02d", m, s)
//    }
//}
//

struct RecalibrateV: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var viewModel: RecalibrationVM
    @State private var recalibrationChoice: RecalibrationType = .breathing
        
    @StateObject private var recalibrationVM = RecalibrationVM()
        
    var body: some View {
        
        let palette = theme.palette(for: .recalibrate)
        
        VStack(spacing: 24) {
            // Header
//            Text.styled("Recalibrate", as: .header, using: fontTheme, in: palette)
            Label("Recalibrate", systemImage: recalibrationChoice.iconName) // image and text
                .font(.largeTitle)
                .foregroundStyle(palette.primary)
            
            // Picker
            Picker("Method", selection: $recalibrationChoice) {
                ForEach(RecalibrationType.allCases, id: \.self) { type in
                    Text("\(type.label)")
                        .font(.caption)
                        .tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Begin/Start Button
            Button(action: {
                viewModel.start(mode: recalibrationChoice)
            }) {
                Label("Begin", systemImage: "play.circle.fill")
                    .font(.title)
            }
            .mainActionStyle(screen: .recalibrate)
            .environmentObject(theme)
            
            // Coundown Displayed
            Text("⏱ \(viewModel.formattedTime)")
                .font(.title2)
                .bold()
                .foregroundStyle(palette.text)
            
            // Instruction List
            ForEach(recalibrationChoice.instructions, id: \.self) { line in
                Text("• \(line)")
            }
            

            // Conditional UI when finished
            if viewModel.phase == .finished {
                Text("✅ Done! Tap to go back")
                    .foregroundColor(palette.text)
                    .padding(.top, 8)
                Text("Tap to post to social")
                    .foregroundStyle(palette.text)
                    .padding(.top, 8)
            }
            
            // Exit Button
            Button("Exit")  {
                viewModel.stop()
            }
            .notMainActionStyle(screen: .recalibrate)
            .environmentObject(theme)
        }
        .padding()
        .onAppear {
            viewModel.start(mode: recalibrationChoice)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(palette.background)
                .shadow(color: palette.primary.opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .padding()
    }
}
#Preview("Recalibrate") {
    PreviewWrapper {
        RecalibrateV(viewModel: RecalibrationVM())
    }
}


