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
        ZStack {
            // True gradient if available
            if let g = p.gradientBackground {
                LinearGradient(colors: g.colors, startPoint: g.start, endPoint: g.end)
                    .ignoresSafeArea()
            } else {
                p.background.ignoresSafeArea()
            }
            
        VStack {
            ScrollView {
                Page {
                    // MARK: H1 centered; prose
                    /*left-aligned = calmer eye path*/
                    T("Reset & Recalibrate", .largeTitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                    
                    // -- separator --
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(p.accent)
                            .frame(height: 1)
                        // ↑ was 4
//                            .padding(.vertical, 8)
                        Rectangle()
                            .fill(p.accent)
                            .frame(height: 1)
                        // ↑ was 4
//                            .padding(.vertical, 4)
                    }
                    
                    // MARK: Supporting copy
                    /* left-aligned, subdued */
                    T("These short physical resets relax and reinvigorate your focus.", .title3)
                        .foregroundStyle(textSecondary)
                        // a bit below the separator
//                        .padding(.top, 1)
                    
                    // -- separator --
                    Rectangle()
                        .fill(p.accent)
                        .frame(height: 1)
                        // was 4, ↑ a touch
                        .padding(.vertical, 4)
                    
                    Spacer()
                    // MARK: Action block
                    T("Choose one below:", .title3)
                        .foregroundStyle(textSecondary)
                        // a bit below the separator
                        .padding(.top, 28)
                    
                    // the ONLY CTA/timer block
                    actionArea
                        .padding(.top, 16)
                    
                    // MARK: Guidance
                    if vm.phase == .none || vm.phase == .idle, let theMode = vm.mode {
                        InstructionList( items: theMode.instructions, p: p, theme: theme )
                            .padding(.top, 12)
                    }
                    
                    // MARK: Live indicators
                    // Balancing - “Switch feet” flashes briefly each minute
                    // Breathing - modes and expanding dot
                    if vm.mode == .balancing {
                        if !vm.eyesClosedMode {
                            // already semi-bold
                            Text(vm.promptText).font(.title3)
                        }
                        BalanceSideDots(activeIndex: vm.balancingPhaseIndex, p: p)
                            .padding(.top, 8)
                        
                    } else if vm.mode == .breathing, vm.phase != .none, vm.phase != .idle {
                        BreathingPhaseGuide(
                            phases: vm.breathingPhases,
                            activeIndex: vm.breathingPhaseIndex,
                            p: p
                        )
                        .padding(.top, 10)
                    }
                }
                // Room for sticky inset + it never covers buttons/picker
                .padding(.bottom, insetHeight + 16)
                .padding(.horizontal, 16)
            }
        }
    }
//        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        // instant task, OK for previews
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
        // MARK: error overlay
        .overlay {
            if let err = vm.lastError {
                ErrorOverlay(error: err) { vm.lastError = nil }
            }
        }
        // MARK: Let people leave
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").imageScale(.small).font(.headline).controlSize(.large)
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

#if DEBUG
#Preview("Recalibrate (dumb)") {
    let theme = ThemeManager()
    let vm    = RecalibrationVM(haptics: NoopHapticsClient())

    return RecalibrationV(vm: vm)
        .environmentObject(theme)
        .frame(maxWidth: 430)
}
#endif
