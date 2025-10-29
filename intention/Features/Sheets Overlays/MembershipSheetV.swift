//
//  MembershipSheetV.swift
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
    
    
    // --- Local Color Definitions ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Hero
                    T("You’ve completed your free sessions.", .label)
                    T("Unlock Unlimited Focus", .header).underline().padding(.top, 2)
                    T("For about 30¢ per day", .secondary).padding(.top, 2)
                        .lineLimit(2)
                }
                .multilineTextAlignment(.center)
                .friendlyHelper()
                Page(top: 10, alignment: .center){      // FIXME: top 10 MAY BE SCREWING THIS UP
                    
                    // Price hint (optional, tiny): Signals if a product is loaded + VM bridge (sheet cannot create own PaymentService)
                    if let prod = viewModel.primaryProduct {
                        Text("\(viewModel.perDayBlurb(for: prod)) • \(prod.displayPrice)")
                            .font(theme.fontTheme.toFont(.headline))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(p.accent).shadow(radius: 8, y: 3)) // subtle lift
                            .foregroundStyle(Color.intText)
                            .padding(.bottom, 6)
                    }
                    
                    // Primary CTA row (above the fold)
                    if viewModel.isMember {
                        Label { T("Member!", .label) } icon: { Image(systemName: "star.fill").foregroundStyle(p.primary)
                        }
                        .symbolBounceIfAvailable()
                    } else {
                        // Upgrade
                        Button {
                            Task {
                                isBusy = true; defer { isBusy = false }
                                do { try await viewModel.purchaseMembershipOrPrompt() }
                                catch { viewModel.setError(error) }      // Shows ErrorOverlay
                            }
                        } label: { T("Upgrade", .action) }
                            .primaryActionStyle(screen: .membership)
                            .frame(maxWidth: .infinity, minHeight: 48)
                        
                        // Restore
                        Button {
                            Task {
                                do { try await viewModel.restoreMembershipOrPrompt() }
                                catch { viewModel.setError(error) }     // Shows ErrorOverlay
                            }
                        } label: { T("Restore Purchases", .label) }
                            .secondaryActionStyle(screen: .membership)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.top, 6)
                        
                        // Apple offer-code redemption (subscription offers)
                        Button {
                            Task { await redeemOfferCode() }
                        } label: { T("Redeem Code (Apple)", .caption) }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                    }
                    
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            T("Why upgrade?", .title3)
                            T("Your focus fuels our future.", .title3).underline()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Unlimited focus sessions", systemImage: "infinity")
                                Label("Detailed stats & categories", systemImage: "chart.bar")
                                Label("Full customization", systemImage: "paintbrush")
                                Divider().padding(.vertical, 4)
                                Label("Build momentum", systemImage: "bolt")
                                Label("Track progress", systemImage: "chart.line.uptrend.xyaxis")
                                Label("\(tailText)", systemImage: "house")
                                Label("Thank you.", systemImage: "heart")
                            }
                            .font(theme.fontTheme.toFont(.footnote))
                            .foregroundStyle(textSecondary)
                            .symbolRenderingMode(.hierarchical)
                            
                            T("Apple securely handles your purchase. Cancel anytime in **Settings › Manage Subscription.**", .caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 6)
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
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
#Preview("Membership — Not Active") {
    MainActor.assumeIsolated {
        // Dedicated, isolated VM for this preview
        let memberVM = MembershipVM(
            payment: PaymentService(productIDs: ["com.argonnesoftware.intention"])
        )
        memberVM._debugSetIsMember(false)    // Preview the non-member state
        
        return MembershipSheetV()
        // Inject the exact env objects MembershipSheetV expects
            .environmentObject(PreviewMocks.theme)
            .environmentObject(memberVM)
        // These keep parity with your app environment
            .environmentObject(PreviewMocks.prefs)
            .environmentObject(PreviewMocks.history)
            .environmentObject(PreviewMocks.stats)
    }
}
#endif

