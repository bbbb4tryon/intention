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
    
    let onSkip: (() -> Void)?
    
    private let breathePreset = 60
    private let balancePreset = 60
    
    // Theme Hooks
    private let screen: ScreenName = .recalibrate
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    @State private var breathingChoice: Int = 2
    @State private var balancingChoice: Int = 2
    
    // MARK: Pickers
    private var BreathPicker: some View {
        HStack(spacing: 8) {
            T("Length", .caption)
                .foregroundStyle(p.text.opacity(0.7))
                .embossed(color: p.text.opacity(0.15)) // Applied here
            
            Picker("", selection: $breathingChoice) {
                Text("2m").tag(2)
                Text("4m").tag(4)
            }
            .pickerStyle(.segmented).opacity(0.85)
        }
        .onChange(of: breathingChoice) { new in
            do { try vm.setBreathingMinutes(new) }
            catch { vm.lastError = error }
        }
    }
    
    private var BalancePicker: some View {
        EmptyView()
            .onChange(of: balancingChoice) { new in
                do { try vm.setBalancingMinutes(new) }
                catch { vm.lastError = error }
            }
    }
    
    init(vm: RecalibrationVM, onSkip: (() -> Void)? = nil) {
        self.vm = vm
        self.onSkip = onSkip
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // MARK: Header
                T("Reset your nervous system", .title3)
                    .foregroundStyle(p.text)
                    .embossed(color: p.text.opacity(0.15))
                    .multilineTextAlignment(.center)
                
                T("A few minutes of guided movement restores focus and momentum", .body)
                    .foregroundStyle(p.text)
                    .embossed(color: p.text.opacity(0.15))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
            
            content
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.25), value: vm.phase)
        }
        .tint(p.accent)
        .task { breathingChoice = vm.currentBreathingMinutes }
    }
    
    @ViewBuilder
    private var content: some View {
        switch vm.phase {
        case .none, .idle:
            chooseView
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .top).combined(with: .opacity)))
        case .running, .pause:
            runView
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
        case .finished:
            chooseView
        }
    }
    
    private var chooseView: some View {
        VStack(spacing: 16) {
            BreathPicker
            
            Button {
                vm.performAsyncAction { try await vm.start(mode: .breathing) }
            } label: {
                T("Breathing", .action)
            }
            .recalibrationActionStyle(screen: screen)
            
            Spacer().frame(height: 22)
            
            BalancePicker
            
            Button {
                vm.performAsyncAction { try await vm.start(mode: .balancing) }
            } label: {
                T("Balancing", .action)
            }
            .recalibrationActionStyle(screen: screen)
            
            Button {
                onSkip?()
                if onSkip == nil { dismiss() }
            } label: {
                T("Skip", .action)
            }
            .opacity(0.85)
        }
    }
    
    private var runView: some View {
        VStack(spacing: 16){
            T(vm.mode == .breathing ? "Breathing" : "Balancing", .section)
                .embossed(color: p.text.opacity(0.15))
            
            Text(vm.formattedTime)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .embossed(color: p.text.opacity(0.1))
            
            RecalProgressBar(progress: progressFraction)
            
            if vm.mode == .breathing {
                T("Follow the rhythm", .caption)
                    .foregroundStyle(p.text.opacity(0.7))
                BreathingPhaseGuide(phases: vm.breathingPhases, activeIndex: vm.breathingPhaseIndex, p: p)
            }
            
            if vm.mode == .balancing {
                T("Switch sides every minute", .caption)
                    .foregroundStyle(p.text.opacity(0.7))
                BalanceSideDots(activeIndex: vm.balancingPhaseIndex)
            }
            
            Button(role: .destructive) {
                vm.performAsyncAction { try await vm.stop() }
            } label: {
                T("End early", .action)
            }
            .recalibrationActionStyle(screen: screen)
        }
        .padding(.top, 12)
    }
    
    private var progressFraction: CGFloat {
        let total = max(1, vm.totalDuration)
        let remaining = max(0, vm.timeRemaining)
        return CGFloat(total - remaining) / CGFloat(total)
    }
}

// MARK: - Global UI Additions (Outside Struct)

struct TextOutlineModifier: ViewModifier {
    let color: Color
    let offset: CGFloat = 0.75

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    content.foregroundStyle(color).offset(x:  offset, y:  offset)
                    content.foregroundStyle(color).offset(x: -offset, y:  offset)
                    content.foregroundStyle(color).offset(x:  offset, y: -offset)
                    content.foregroundStyle(color).offset(x: -offset, y: -offset)
                }
            )
    }
}

    extension View {
        func embossed(color: Color = Color(red: 0.239, green: 0.314, blue: 0.0)) -> some View {
            self.modifier(TextOutlineModifier(color: color))
        }
        
//        func readHeight(_ binding: Binding<CGFloat>) -> some View {
//            background(HeightReader { binding.wrappedValue = $0 })
//                .onPreferenceChange(HeightKey.self) { binding.wrappedValue = $0 }
//        }
    }

// MARK: - Progress Bar
private struct RecalProgressBar: View {
    let progress: CGFloat
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5).fill(Color.intGreen.opacity(0.35))
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: [.intGreen, .intGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }.frame(height: 10)
    }
}

//private extension View {
//    func readHeight(_ binding: Binding<CGFloat>) -> some View {
//        background(HeightReader { binding.wrappedValue = $0 })
//            .onPreferenceChange(HeightKey.self) { binding.wrappedValue = $0 }
//    }
//}
//
//// MARK: error overlay
//.overlay {
//    if let err = vm.lastError {
//        // block any sheet behind it -- ErrorOverlay handles own taps
//        ErrorOverlay(error: err) { vm.lastError = nil }
//            .allowsHitTesting(true)
//            .transition(.opacity)
//            .zIndex(1)
//    }
//}
//// only block tapping/interaction when error is visible
//.allowsHitTesting(vm.lastError == nil)
//}

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
