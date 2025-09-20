//
//  RecalibrateV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

extension View {
    func forceLabelWhite() -> some View { self.foregroundStyle(.white).tint(.white) }
}

struct RecalibrationV: View {
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var vm: RecalibrationVM
    @State private var breathingChoice: Int = 2
    @State private var balancingChoice: Int = 2
    
    // Tunable presets users expect: quick, obvious, one tap.
    private let breathePreset = 60   // 1 min
    private let balancePreset = 60   // 1 min
    
    private let screen: ScreenName = .recalibrate
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        ScrollView {
                Page {
                    // H1 centered; prose left-aligned = calmer eye path
                    T("Reset & Recalibrate", .largeTitle).underline()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                    
                    // Supporting copy: left-aligned, subdued
                    T("Short resets help you start your next 20-minute focus chunk fresh.", .body)
                        .foregroundStyle(p.textSecondary)
                    
                    T("Choose one below:", .caption)
                        .foregroundStyle(p.textSecondary)
                    
                    actionArea                          // the ONLY CTA/timer block
                    
                    // Lightweight guidance
                    if vm.phase == .idle, let theMode = vm.mode {
                        InstructionList( items: theMode.instructions, p: p, theme: theme )
                            .padding(.top, 8)
                    }
                    
                    // Live indicators
                    if vm.mode == .balancing {
                        if !vm.eyesClosedMode {
                            Text(vm.promptText) // “Switch feet” flashes briefly each minute
                                .font(.title3).fontWeight(.semibold)
                        }
                        BalanceSideDots(activeIndex: vm.balancingPhaseIndex, p: p)
                            .padding(.top, 6)
                    } else if vm.mode == .breathing, vm.phase != .idle {
                        BreathingPhaseGuide(
                            phases: vm.breathingPhases,
                            activeIndex: vm.breathingPhaseIndex,
                            p: p
                        )
                        .padding(.top, 6)
                    }
                }
            }
            .background(p.background.ignoresSafeArea())
            .task { breathingChoice = vm.currentBreathingMinutes }
            .presentationDetents([.fraction(0.4), .medium])   // iOS 16-friendly
            .presentationDragIndicator(.visible)
            .overlay {
                if let err = vm.lastError {
                    ErrorOverlay(error: err) { vm.lastError = nil }
                }
            }
    }
        
        // MARK: Helpers
        private var PresetPicker: some View {
            HStack(spacing: 8) {
                T("Breathing length", .caption).foregroundStyle(.secondary)
                Picker("", selection: $breathingChoice) {
                    Text("2m").tag(2); Text("3m").tag(3); Text("4m").tag(4)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
            .onChange(of: breathingChoice) { new in
                do { try vm.setBreathingMinutes(new) } catch { vm.lastError = error }
            }
        }
    private var PresetPickerBal: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $vm.eyesClosedMode) {
                T("Eyes-closed expert mode", .caption).foregroundStyle(.secondary)
            }
                .toggleStyle(.switch)
//            Picker("", selection: $balancingChoice) {
//                Text("Yes").tag(2); Text("No").tag(3)
//            }
//            .pickerStyle(.segmented)
            .frame(maxWidth: 320)
            
        }
        .onChange(of: balancingChoice) { new in
            do { try vm.setBalancingMinutes(new) } catch { vm.lastError = error }
        }
    }
        
        @ViewBuilder
           private var actionArea: some View {
               switch vm.phase {
               case .idle:
                   VStack(spacing: 12) {
                       if vm.phase == .idle { PresetPicker }   // 2m / 3m / 4m
                       Button {
                           vm.performAsyncAction { try await vm.start(mode: .breathing) }
                       } label: { T("Breathing", .action).foregroundColor(.white) }
                           .recalibrationActionStyle(screen: screen)

                       if vm.phase == .idle { PresetPickerBal }   // 2m / 3m / 4m
                       Button {
                           vm.performAsyncAction { try await vm.start(mode: .balancing) }
                       } label: { T("Balancing", .action) }
                           .recalibrationActionStyle(screen: screen)
                   }

               case .running, .pause:
                   VStack(spacing: 8) {
                       T(vm.mode == .breathing ? "Breathing" : "Balancing", .section)
                           .frame(maxWidth: .infinity, alignment: .center)

                       Text(vm.formattedTime)
                           .font(.system(size: 56, weight: .semibold, design: .rounded))
                           .monospacedDigit()
                           .frame(maxWidth: .infinity, alignment: .center)

                       Button(role: .destructive) {
                           vm.performAsyncAction { try await vm.stop() }
                       } label: { T("Cancel", .action) }
                   }

               case .finished:
                   EmptyView()
               }
           }
       }
    // Tiny, reusable instruction list (keeps body tidy)
    private struct InstructionList: View {
        let items: [String]
        let p: ScreenStylePalette
        let theme: ThemeManager
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { Text("• \($0)") }
            }
            .font(theme.fontTheme.toFont(.footnote))
            .foregroundStyle(p.text)
        }
    }
    
//
//                    
//                    /// users tap a length first (2/3/4), then “Breathe.”
//                    if vm.phase == .idle {
//                        HStack(spacing: 8) {
//                            T("Breathing length", .caption)
//                                .foregroundStyle(.secondary)
//                            Picker("", selection: $breathingChoice) {
//                                Text("2m").tag(2)
//                                Text("3m").tag(3)
//                                Text("4m").tag(4)
//                            }
//                            .pickerStyle(.segmented)
//                            .frame(maxWidth: 220)
//                        }
//                        .onChange(of: breathingChoice) { new in
//                            do { try vm.setBreathingMinutes(new) }
//                            catch { vm.lastError = error }
//                        }
//                    }
//                    
//                    /// When inactive, show simple, obvious choices
//                    if vm.phase != .running {
//                        VStack(spacing: 12) {
//                            if vm.mode == nil {
//                                Button { start(.breathing) } label: {
//                                    HStack(spacing: 8){
//                                        Image(systemName: RecalibrationMode.breathing.iconName)
//                                        T(activeTitle, .largeTitle)
//                                    }
//                                    .frame(maxWidth: .infinity)
//                                }
//                                .primaryActionStyle(screen: .recalibrate)
//                                
//                                Button { start(.balancing) } label: {
//                                    HStack(spacing: 8){
//                                        Image(systemName: RecalibrationMode.balancing.iconName)
//                                        T(activeTitle, .largeTitle)
//                                    }
//                                    .frame(maxWidth: .infinity)
//                                }
//                                .primaryActionStyle(screen: .recalibrate)
//                            }
//                        }
//                    } else {
//                        /// Active countdown view: big, legible, tappable cancel
//                        VStack(spacing: 16) {
//                            Text(activeTitle)
//                                .font(.headline)
//                            Text(vm.formattedTime)
//                                .font(.system(size: 56, weight: .semibold, design: .rounded))
//                                .monospacedDigit()
//                            Button(role: .destructive) { stop() } label: {
//                                Label("Cancel", systemImage: "xmark.circle")
//                                    .frame(maxWidth: .infinity)
//                                    .tint(.red)
//                            }
//                        }
//                        .padding(.top, 8)
//                    }
//                    // instructions for the selected mode:
//                    if let m = vm.mode, vm.phase != .running {
//                        VStack(alignment: .leading, spacing: 4) {
//                            ForEach(m.instructions, id: \.self) { Text("• \($0)") }
//                        }
//                        .font(theme.fontTheme.toFont(.footnote))
//                        .foregroundStyle(p.text)
//                        .padding(.top, 8)
//                    }
//                    
//                    VStack(spacing: 8) {
//                        if vm.mode == .balancing {
//                            Text(vm.promptText) // shows “Switch feet” briefly each minute
//                                .font(.title3).fontWeight(.semibold)
//                        } else if vm.mode == .breathing {
//                            BreathingPhaseGuide(
//                                phases: vm.breathingPhases,
//                                activeIndex: vm.breathingPhaseIndex,
//                                p: p
//                            )
//                            HStack(spacing: 6) {
//                                ForEach(Array(vm.breathingPhases.enumerated()), id: \.0) { idx, name in
//                                    if idx == vm.breathingPhaseIndex { Text("• \(name)") } else { Text(name) }
//                                    if idx != vm.breathingPhases.count - 1 { Text("·").opacity(0.6) }
//                                }
//                            }
//                            .font(.headline)
//                            .monospacedDigit()
//                        }
//                        //                    Text(vm.formattedTime).font(.system(.largeTitle, design: .rounded)).monospacedDigit()
//                    }
//                    
//                }
//                .task { breathingChoice = vm.currentBreathingMinutes }
//                .presentationDetents([.height(320), .medium])
//                .presentationDragIndicator(.visible)
//                
//                // Error overlay—same pattern as the rest of the app
//                if let err = vm.lastError {
//                    ErrorOverlay(error: err) { vm.lastError = nil }
//                        .zIndex(1)
//                }
//            }
//            .background(p.background.ignoresSafeArea())
//        }
//    }

// struct RecalibrateV: View {
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
// }
#if DEBUG
#Preview("Recalibrate") {
    PreviewWrapper {
        RecalibrationV(vm: RecalibrationVM(haptics: NoopHapticsClient()))
            .previewTheme()
    }
}
#endif
