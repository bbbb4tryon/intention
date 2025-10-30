//
//  RecalibrateV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

struct RecalibrationV: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject var vm: RecalibrationVM
    @State private var insetHeight: CGFloat = 72        // height of sticky bar
    @State private var breathingChoice: Int = 2
    @State private var balancingChoice: Int = 2
    @State private var isBusy = false
    
    // Tunable presets users expect: quick, obvious, one tap.
    private let breathePreset = 60   // 1 min
    private let balancePreset = 60   // 1 min
    
    private let screen: ScreenName = .recalibrate
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    // --- Local Color Definitions ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        VStack {
            ScrollView {
                Page {
                    // H1 centered; prose left-aligned = calmer eye path
                    T("Reset & Recalibrate", .largeTitle)
                    // really want flair? use a 1-pt bottom divider below the title instead of underline
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                    
                    // Supporting copy: left-aligned, subdued
                    T("Short resets help you start your next 20-minute focus chunk fresh.", .body)
                        .foregroundStyle(textSecondary)
                    
                    T("Choose one below:", .body)
                        .foregroundStyle(textSecondary)
                    
                    // the ONLY CTA/timer block
                    actionArea
                        .padding(.top)
                    
                    // Lightweight guidance
                    //FIXME: or use == .none or .notStarted?
                    if vm.phase == .none || vm.phase == .idle, let theMode = vm.mode {
                        InstructionList( items: theMode.instructions, p: p, theme: theme )
                            .padding(.top, 8)
                    }
                    
                    // Live indicators:
                    // Balancing - “Switch feet” flashes briefly each minute
                    // Breathing - modes and expanding dot
                    if vm.mode == .balancing {
                        if !vm.eyesClosedMode {
                            Text(vm.promptText)
                                .font(.title3).fontWeight(.semibold)
                        }
                        BalanceSideDots(activeIndex: vm.balancingPhaseIndex, p: p)
                            .padding(.top, 6)
                    } else if vm.mode == .breathing, vm.phase != .none, vm.phase != .idle {
                        BreathingPhaseGuide(
                            phases: vm.breathingPhases,
                            activeIndex: vm.breathingPhaseIndex,
                            p: p
                        )
                        .padding(.top, 6)
                    }
                }
                // Room for sticky inset + it never covers buttons/picker
                .padding(.bottom, insetHeight + 16)
                .padding(.horizontal, 16)
            }
        }
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        .task { breathingChoice = vm.currentBreathingMinutes }
        .presentationDragIndicator(.visible)
        // Fill-height sheet so users don’t have to expand it first
        .presentationDetents([.large])
        // Sticky bottom chrome
//        .safeAreaInset(edge: .bottom, spacing: 0) {
//            BottomInset
//                .background(.ultraThinMaterial)
//                .readHeight($insetHeight)   // helper below to measure height
//        }
        .overlay {
            if let err = vm.lastError {
                ErrorOverlay(error: err) { vm.lastError = nil }
            }
        }
        // Let people leave
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").imageScale(.small).font(.body).controlSize(.large)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
    }
    
    
    // MARK: Helpers
    private var PresetPicker: some View {
        HStack(spacing: 8) {
            // theme drives contract, don't need .foregroundStyle
            T("Length of Time", .caption)
            Picker("", selection: $breathingChoice) {
                Text("2m").tag(2); Text("3m").tag(3); Text("4m").tag(4)
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: breathingChoice) { new in
            do { try vm.setBreathingMinutes(new) } catch { vm.lastError = error }
        }
    }
    private var PresetPickerBal: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $vm.eyesClosedMode) {
                T("Expert Mode: Eyes-closed", .caption)
            }
            .toggleStyle(.automatic)
        }
        .onChange(of: balancingChoice) { new in
            do { try vm.setBalancingMinutes(new) } catch { vm.lastError = error }
        }
    }
    
    @ViewBuilder
    private var actionArea: some View {
        switch vm.phase {
        case .none, .idle:
            VStack(spacing: 12) {
                if vm.phase == .none || vm.phase == .idle { PresetPicker }   // 2m / 3m / 4m
                Button {
                    vm.performAsyncAction { try await vm.start(mode: .breathing) }
                } label: { T("Breathing", .action) }
                    .recalibrationActionStyle(screen: screen)
                
                Divider()
                if vm.phase == .none || vm.phase == .idle { PresetPickerBal }
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
                } label: { T("Cancel", .action)
                        .recalibrationActionStyle(screen: screen)
                }
            }
        case .finished:
            EmptyView()
        }
    }
    // Sticky chrome above the Home indicator (keep it simple; no refactor of actionArea)
//    @ViewBuilder
//    private var BottomInset: some View {
//        VStack(spacing: 8) {
//            // a subtle handle/status—tweak as you like
//            HStack {
////                Text(vm.phase == .running || vm.phase == .pause ? "Recalibration in progress" : "Ready")
//                Text(vm.phase == .running || vm.phase == .pause ? "" : "")
//                    .font(.footnote).foregroundStyle(.secondary)
//                Spacer()
//                if vm.phase == .running || vm.phase == .pause {
//                    Text(vm.formattedTime)
//                        .font(.title3.bold()).monospacedDigit()
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.top, 10)
//            
//            // keep a comfortable tap zone above the home indicator
//            Color.clear.frame(height: 16)
//        }
//    }
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
    private struct HeightReader: View {
        var onChange: (CGFloat) -> Void
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeightKey.self, value: proxy.size.height)
            }
        }
    }
    private struct HeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    private extension View {
        func readHeight(_ binding: Binding<CGFloat>) -> some View {
            background(HeightReader { binding.wrappedValue = $0 })
                .onPreferenceChange(HeightKey.self) { binding.wrappedValue = $0 }
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
#Preview("Recalibrate - Running") {
    PreviewWrapper {
//        RecalibrationV(vm: PreviewMocks.recalibrationRunning())
//            .previewTheme()(haptics: NoopHapticsClient())
        RecalibrationV(vm: RecalibrationVM.mockForDebug()).previewTheme()
            .previewTheme()
    }
}
#endif
