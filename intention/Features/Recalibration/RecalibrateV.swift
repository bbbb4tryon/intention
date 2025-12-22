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
    
    // Optional callback to skip recalibration entirely
    let onSkip: (() -> Void)?
    @State private var insetHeight: CGFloat = 72        // height of sticky bar
    @State private var breathingChoice: Int = 2
    @State private var balancingChoice: Int = 2
    @State private var isBusy = false
    
    // Tunable presets users expect: quick, obvious, one tap.
    private let breathePreset = 60   // 1 min
    private let balancePreset = 60   // 1 min

    // Theme Hooks
    private let screen: ScreenName = .recalibrate
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    private let recColor = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5
    
    // MARK: Computed helpers
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
    
    init(vm: RecalibrationVM, onSkip: (() -> Void)? = nil) {
        self.vm = vm
        self.onSkip = onSkip
    }
    
    var body: some View {
        ZStack {
//Chrome paints gradient + texture, leave clear
            Color.clear
        VStack {
            ScrollView {
                Page {
                    // MARK: - Header
                    T("Reset your nervous system", .header)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                    
                    T("A few minutes of guided movement restores focus and momentum", .title3)
                        .foregroundStyle(textSecondary)
                        .multilineTextAlignment(.center)
                    
                    T("Choose one below:", .title3)
                        .foregroundStyle(textSecondary)
                        // a bit below the separator
                        .padding(.top, 10)
                        .padding(.horizontal, 8)
                    
                    // MARK: Action and spacing
                    actionArea
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    
                    // MARK: Guidance
                    if vm.phase == .none || vm.phase == .idle, let theMode = vm.mode {
                        InstructionList( items: theMode.instructions, p: p, theme: theme )
                            .padding(.top, 12)
                    }
                    
                    // MARK: Live indicators
                    if vm.mode == .balancing {
                        T("Switch sides every minute", .caption)
                            .foregroundStyle(p.text)
                        
                        RecalProgressBar(progress: progressFraction)
                            .padding(.top, 8)
                        
                        // Balancing - “Switch feet” flashes briefly each minute
                        BalanceSideDots(activeIndex: vm.balancingPhaseIndex)
                                .padding(.top, 12)
                    } else if vm.mode == .breathing, vm.phase != .none, vm.phase != .idle {
                        T("Follow the rhythm below", .caption)
                            .foregroundStyle(p.text)
                            .padding(.top, 6)
                        
                        RecalProgressBar(progress: progressFraction)
                            .padding(.top, 8)
                        
                        // Breathing - modes and expanding dot
                        BreathingPhaseGuide(
                            phases: vm.breathingPhases,
                            activeIndex: vm.breathingPhaseIndex,
                            p: p
                        )
                        .padding(.top, 10)
                    }
                }
                // Sticky: never covers buttons/picker
                .padding(.bottom, insetHeight + 16)
                .padding(.horizontal, 16)
            }
        }
    }

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
                // block any sheet behind it -- ErrorOverlay handles own taps
                ErrorOverlay(error: err) { vm.lastError = nil }
                    .allowsHitTesting(true)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // only block tapping/interaction when error is visible
        .allowsHitTesting(vm.lastError == nil)
        
        // MARK: Let people leave
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "x.square").imageScale(.large).font(.headline).controlSize(.large)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
    }
    
    // MARK: - ViewBuilder: actionArea
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
                
                // MARK: skip path -> routes back to Focus without running --
                Button {
                    // Allows reset focusVM and closing the sheet
                    onSkip?()
                    // Fallback: dismiss locally
                    if onSkip == nil { dismiss() }
                } label: {
                    T("Skip", .action)
                        .recalibrationActionStyle(screen: screen)
                        .tint(p.accent)
                        .shadow(color: Color.blue.opacity(0.09), radius: 8, x: 0, y: 3)
                        .opacity(0.9)
                        .accessibilityIdentifier(("Skip recalibration screen"))
                }
            }
            
        case .running, .pause:
            VStack(spacing: 8) {
                T(vm.mode == .breathing ? "Breathing" : "Balancing", .section)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(vm.formattedTime)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                RecalProgressBar(progress: progressFraction)
                    .padding(.top, 4)
                
                // Keeping and explicit "end early"
                Button(role: .destructive) {
                    vm.performAsyncAction { try await vm.stop() }
                } label: {
                    T("End early", .action)
                        .recalibrationActionStyle(screen: screen)
                }
            }
        case .finished:
            EmptyView()
        }
    }
}

// MARK: Progress bar for Recalibration
private struct RecalProgressBar: View {
    let progress: CGFloat   // 0.0 ... 1.0
//    let p: ScreenStylePalette
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 10
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: h/2)
                    .fill(Color.intGreen.opacity(0.35))
                    .frame(height: h)
                
                // Progress fill - company green gradient
                RoundedRectangle(cornerRadius: h/2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.intGreen,
                                Color.intGreen.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(1, progress)) * w, height: h)
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: Progress calculation helper
private extension RecalibrationV {
    var progressFraction: CGFloat {
        let total = max(1, vm.totalDuration)
        let remaining = max(0, vm.timeRemaining)
        let done = total - remaining
        return CGFloat(Double(done) / Double(total))
    }
}
    // MARK: - Computed Helpers
    private struct InstructionList: View {
        let items: [String]
        let p: ScreenStylePalette
        let theme: ThemeManager
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { Text("Now, Lift \($0)") }
            }
            .padding()
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

    RecalibrationV(vm: vm, onSkip: {})
        .environmentObject(theme)
    /* read ONLY if/when everything else is stable */
    /// .canvasCheap()
        .frame(maxWidth: 430)
}
#endif
