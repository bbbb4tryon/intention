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
    
    @State private var isFavorite = false
    @State var codeInput: String = ""
    @State private var isBusy = false
    
    private let screen: ScreenName = .membership
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    // replaces fragile chunk with a validated block
    private var codeValidation: ValidationState {
        codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? .invalid(messages: ["Enter a code"])
        : .valid
    }
    
    var body: some View {
        NavigationStack {
            Page {
                T("Unlock Unlimited Focus", .section)
                    .friendlyHelper()
                
                T("You’ve completed your free sessions. For just 20–30¢ a day, unlock unlimited focus sessions, detailed stats, more categories, and full customization. Build momentum, track progress, and work with intention — while helping us keep the lights on, the mortgage paid, and the dog well-fed. Your focus fuels our future. Thank you.", .body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.palette(for: .membership).textSecondary)
                //
                //                    theme.styledText("By continuing, you agree to our Terms and Privacy.", as: .caption, in: .membership))
                //                        .font(theme.fontTheme.toFont(.footnote))
                //                        .foregroundStyle(.secondary)
                //                        .padding(.bottom, 8)
                
                // Primary CTA row (above the fold)
                if viewModel.isMember {
                    Label { T("Member!", .label) } icon: { Image(systemName: "star.fill").foregroundStyle(p.primary)
                    }
                    .symbolBounceIfAvailable()
                } else {
                    Button {
                        Task {
                            do { try await viewModel.purchaseMembershipOrPrompt() }
                            catch { debugPrint("[viewModel.purchaseMembershipOrPrompt] error: ", error); viewModel.setError(error) } }      /// Shows ErrorOverlay
                    } label: { T("Upgrade Membership", .action) }
                        .primaryActionStyle(screen: .membership)
                    
                    Button {
                        Task {
                            do { try await viewModel.restoreMembershipOrPrompt() }
                            catch { debugPrint("[viewModel.restoreMembershipOrPrompt] error: ", error); viewModel.setError(error) } }        /// Shows ErrorOverlay
                    } label: { T("Restore Purchases", .label)}
                        .secondaryActionStyle(screen: .membership)
                    
                    // Price hint (optional, tiny): Signals if a product is loaded + VM bridge (sheet cannot create own PaymentService)
                    if let prod = viewModel.primaryProduct {
                        Text("\(viewModel.perDayBlurb(for: prod)) • \(prod.displayPrice)")
                            .font(theme.fontTheme.toFont(.footnote))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Keep your required long copy, but collapse it
                    DisclosureGroup {
                        T("You’ve completed your free sessions. For just 20–30¢ a day, unlock unlimited focus sessions, detailed stats, more categories, and full customization. Build momentum, track progress, and work with intention — while helping us keep the lights on, the mortgage paid, and the dog well-fed. Your focus fuels our future. Thank you.", .body)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(p.textSecondary)
                    } label: {
                        T("Why upgrade?", .caption)
                    }
                    
                    
                    if !AppEnvironment.isAppStoreReviewing {
                        Divider().padding(.top, 4)
                        
                        Button {
                            Task {
                                if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                    await UIApplication.shared.open(url)
                                } else { debugPrint("[MembershipSheetV.isAppStoreReviewing] bad URL"); viewModel.setError(MembershipError.appEnvironmentFail) } }  /// Shows ErrorOverlay
                        } label: { T("Visit Website", .section) }
                            .primaryActionStyle(screen: .membership)
                            .underline()
                        
                        // Code entry: reveal on tap
                        DisclosureGroup {
                            VStack(spacing: 8) {
                                ZStack(alignment: .leading) {
                                    if codeInput.isEmpty {
                                        T("Enter code", .placeholder) .padding(.horizontal, 12)
                                    }
                                    TextField("", text: $codeInput)
                                        .textInputAutocapitalization(.characters)
                                        .disableAutocorrection(true)
                                        .validatingField(state: codeValidation, palette: p)
                                }
                                ValidationCaption(state: codeValidation, palette: p)
                                
                                
                                Button { viewModel.showCodeEntry = true
                                    Task {
                                        if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                            await UIApplication.shared.open(url)
                                        } else { debugPrint("[MembershipSheetV.isAppStoreReviewing] bad URL"); viewModel.setError(MembershipError.appEnvironmentFail) }}   /// Shows ErrorOverlay
                                } label: { T("Enter Membership Code", .label) }
                                    .primaryActionStyle(screen: .membership)
                            }
                                
                                if viewModel.showCodeEntry {
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .leading) {
                                            Button {
                                                Task {
                                                    do { try await viewModel.verifyCode(codeInput) }
                                                    catch { debugPrint("[MembershipSheetV.showCodeEntry] error: ", error); viewModel.setError(error) } } /// Shows ErrorOverlay
                                            } label: { T("Redeem", .label) }
                                                .primaryActionStyle(screen: .membership)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    /// Overlay shown if there is a lastError
                    if let error = viewModel.lastError {
                        ErrorOverlay(error: error) {
                            viewModel.setError(nil)  /// Dismiss
                        }
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1)
                    }
                }
                    .background(p.background.ignoresSafeArea())
                    .tint(p.primary)
                    .toolbar { ToolbarItem(placement: .cancellationAction ){
                        Button( "Close") { dismiss() }}} // Let people leave
            }
        }
    }
// Sheet behavior tuned for iPhone
.presentationDetents([.fraction(0.5), .large])
.presentationDragIndicator(.visible)
.interactiveDismissDisabled(false)
}
#if DEBUG
extension MembershipVM {
    @MainActor
    func _previewSet(member: Bool) {
        // Adjust these lines to match your properties if names differ.
        self.isMember = member
        // Optional: also fake a product if your UI needs it
        // self.primaryProduct = nil
    }
}
#endif

#if DEBUG
#Preview("Membership — Non-Member") {
    // Uses your PreviewWrapper + default mocks
    PreviewWrapper {
        MembershipSheetV()
    }
}

#Preview("Membership — Member") {
    MainActor.assumeIsolated {
        // Create an isolated VM so we don’t mutate shared PreviewMocks.membershipVM
        let memberVM = MembershipVM()
        memberVM._previewSet(member: true)
        
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
