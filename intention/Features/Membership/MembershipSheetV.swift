//
//  Sheet.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//
//
// import Foundation
import SwiftUI

struct MembershipSheetV: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: MembershipVM
    @EnvironmentObject var theme: ThemeManager
    
    @State private var isBusy = false
    
    var useDogEmoji: Bool = true
    private let screen: ScreenName = .membership
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    // 1) Place this INSIDE the struct, but OUTSIDE `body`
    private var tailText: String { "All while helping us keep the lights on, the mortgage paid, and the \(useDogEmoji ? "🐕" : "dog") fed & happy!" }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Hero
                    T("You’ve completed your free sessions.", .label)
                    T("""
For $0.30 Per Day, 
Unlock Unlimited Focus
""", .section).underline().padding(.top, 2)
                        .lineLimit(2)
                }
                .multilineTextAlignment(.center)
                .friendlyHelper()
                Page(top: 10, alignment: .center){      // FIXME: top 10 MAY BE SCREWING THIS UP
                    
                    // Price hint (optional, tiny): Signals if a product is loaded + VM bridge (sheet cannot create own PaymentService)
                    if let prod = viewModel.primaryProduct {
                        Text("\(viewModel.perDayBlurb(for: prod)) • \(prod.displayPrice)")
                            .font(theme.fontTheme.toFont(.headline))
                            .background(RoundedRectangle(cornerRadius: 12).fill(p.accent))
                            .foregroundStyle(Color.intText)
                            .padding(.bottom, 4)
                    }
                    
                    // Primary CTA row (above the fold)
                    if viewModel.isMember {
                        Label { T("Member!", .label) } icon: { Image(systemName: "star.fill").foregroundStyle(p.primary)
                        }
                        .symbolBounceIfAvailable()
                    } else {
                        Button {
                            Task {
                                isBusy = true
                                defer { isBusy = false }
                                do { try await viewModel.purchaseMembershipOrPrompt() }
                                catch { debugPrint("[viewModel.purchaseMembershipOrPrompt] error: ", error); viewModel.setError(error) } }      /// Shows ErrorOverlay
                        } label: { T("Upgrade", .label) }
                            .primaryActionStyle(screen: .membership).frame(maxWidth: .infinity)
                        
                        Button {
                            Task {
                                do { try await viewModel.restoreMembershipOrPrompt() }
                                catch { debugPrint("[viewModel.restoreMembershipOrPrompt] error: ", error); viewModel.setError(error) } }        /// Shows ErrorOverlay
                        } label: { T("Restore Purchases", .action)}
                            .secondaryActionStyle(screen: .membership).frame(maxWidth: .infinity)
                        
                        // Apple offer-code redemption (subscription offers)
                        Button {
                            Task { await redeemOfferCode() }
                        } label: { T("Redeem Code (Apple)", .caption) }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                    }
                    
                    Card {
                        VStack(alignment: .leading, spacing: 2) {
                            T("Why upgrade?", .title3)
                            T("Your focus fuels our future.", .title3).underline()
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Unlimited focus sessions", systemImage: "infinity")
                                Label("Detailed stats & categories", systemImage: "chart.bar")
                                Label("Full customization", systemImage: "paintbrush")
                                Divider().padding()
                                Label("Build momentum", systemImage: "bolt")
                                Label("Track progress", systemImage: "chart.line.uptrend.xyaxis")
                                Label("\(tailText)", systemImage: "house")
                                Label("Thank you.", systemImage: "heart")
                            }
                            .font(theme.fontTheme.toFont(.footnote))
                            .foregroundStyle(p.textSecondary)
                            .symbolRenderingMode(.hierarchical)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple securely handles your purchase. Cancel anytime in **Settings › Manage Subscription.**")
                                    .font(theme.fontTheme.toFont(.caption))
                                    .foregroundStyle(.secondary)
                                    .padding(.top)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .background(p.background.ignoresSafeArea())
            .tint(p.primary)
            // Let people leave
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button{ dismiss() }
                    label: { Image(systemName: "xmark").imageScale(.small).font(.body).controlSize(.large) }.buttonStyle(.plain).accessibilityLabel("Close")}
            }
        }
        // Sheet behavior tuned for iPhone
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
        .overlay {
            if isBusy { ProgressView().controlSize(.large) }
        }
        .overlay {
            if let error = viewModel.lastError {
                ErrorOverlay(error: error) { viewModel.setError(nil) }
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1)
            }
        }
    }
}


#if DEBUG
extension MembershipVM {
    @MainActor
    func _previewSet(inActive: Bool) {
        // Adjust these lines to match your properties if names differ.
        self.isMember = inActive
        // Optional: also fake a product if your UI needs it
        self.primaryProduct = nil
    }
}
#endif

#if DEBUG
//#Preview("Membership — Not Active") {
//    // Uses your PreviewWrapper + default mocks
//    PreviewWrapper {
//        MembershipSheetV()
//    }
//}

#Preview("Membership — Not Active") {
    MainActor.assumeIsolated {
        // Create an isolated VM so we don’t mutate shared PreviewMocks.membershipVM
        let memberVM = MembershipVM()
        memberVM._previewSet(inActive: true)
        
        return MembershipSheetV()
        // Inject the exact env objects MembershipSheetV expects
            .environmentObject(PreviewMocks.theme)
            .environmentObject(memberVM)
        // The rest are harmless and keep parity with app environment
            .environmentObject(PreviewMocks.prefs)
            .environmentObject(PreviewMocks.history)
            .environmentObject(PreviewMocks.stats)
    }
}
#endif
