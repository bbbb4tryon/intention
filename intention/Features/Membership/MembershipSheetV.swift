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
    @EnvironmentObject var viewModel: MembershipVM
    @EnvironmentObject var theme: ThemeManager
    
    @State private var isFavorite = false
    @State var codeInput: String = ""
    
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
        ZStack {
            ScrollView {
                Page {
                    T("Unlock Unlimited Focus", .section)
                    //                        .multilineTextAlignment(.center)
                        .friendlyHelper()
                    
                    T("You’ve completed your free sessions. For just 20–30¢ a day, unlock unlimited focus sessions, detailed stats, more categories, and full customization. Build momentum, track progress, and work with intention — while helping us keep the lights on, the mortgage paid, and the dog well-fed. Your focus fuels our future. Thank you.", .body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.palette(for: .membership).textSecondary)
                    //
                    //                    theme.styledText("By continuing, you agree to our Terms and Privacy.", as: .caption, in: .membership))
                    //                        .font(theme.fontTheme.toFont(.footnote))
                    //                        .foregroundStyle(.secondary)
                    //                        .padding(.bottom, 8)
                    
                    if viewModel.isMember {
                        Label {
                            T("Member!", .label)
                        } icon: {
                            Image(systemName: "star")
                        }
                        .symbolBounceIfAvailable()
                    } else {
                        Button( action: {
                            Task {
                                do {
                                    try await viewModel.purchaseMembershipOrPrompt()
                                } catch {
                                    debugPrint("[viewModel.purchaseMembershipOrPrompt] error: ", error)
                                    viewModel.setError(error)                /// Shows ErrorOverlay
                                }
                            }
                        }) {
                            T("Upgrade Membership", .action)
                        }
                        .primaryActionStyle(screen: .membership)
                        
                        Button(action:
                                {
                            Task {
                                do {
                                    try await viewModel.restoreMembershipOrPrompt()
                                } catch {
                                    debugPrint("[viewModel.restoreMembershipOrPrompt] error:", error)
                                    viewModel.setError(error)                /// Shows ErrorOverlay
                                    // _ = await MainActor.run {  MembershipError.restoreFailed }
                                }
                            }
                        }) {
                            T("Restore Purchases", .label)
                        }
                        .secondaryActionStyle(screen: .membership)
                        
                        if !AppEnvironment.isAppStoreReviewing {
                            Divider()
                            Button(action: {
                                Task {
                                    if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                        await UIApplication.shared.open(url)
                                    } else {
                                        debugPrint("[MembershipSheetV.isAppStoreReviewing] bad URL" )
                                        viewModel.setError(MembershipError.appEnvironmentFail)   /// Shows ErrorOverlay
                                    }
                                }
                            }) {
                                T("Visit Website", .section)
                            }
                            .primaryActionStyle(screen: .membership)
                            .underline()
                            
                            VStack(spacing: 12) {
                                
                                Button( action: {
                                    viewModel.showCodeEntry = true
                                    Task {
                                        if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                            await UIApplication.shared.open(url)
                                        } else {
                                            debugPrint("[MembershipSheetV.isAppStoreReviewing] bad URL" )
                                            viewModel.setError(MembershipError.appEnvironmentFail)   /// Shows ErrorOverlay
                                        }
                                    }
                                }) {
                                    T("Enter Membership Code", .label)
                                }
                                .primaryActionStyle(screen: .membership)
                                
                                if viewModel.showCodeEntry {
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .leading) {
                                            if codeInput.isEmpty {
                                                T("Enter code", .placeholder)
                                                    .padding(.horizontal, 12)
                                            }
                                            TextField("", text: $codeInput)
                                                .textInputAutocapitalization(.characters)
                                                .disableAutocorrection(true)
                                                .validatingField(state: codeValidation, palette: p)
                                        }
                                        
                                        ValidationCaption(state: codeValidation, palette: p)
                                        
                                        Button {
                                            Task {
                                                do { try await viewModel.verifyCode(codeInput) } catch {
                                                    debugPrint("[MembershipSheetV.showCodeEntry] error: ", error )
                                                    viewModel.setError(error)                /// Shows ErrorOverlay
                                                }
                                            }
                                        } label: {
                                            T("Redeem", .label)
                                        }
                                        .primaryActionStyle(screen: .membership)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                /// Signals if a product is loaded + VM bridge (sheet cannot create own PaymentService)
                if let prod = viewModel.primaryProduct {
                    Text("\(viewModel.perDayBlurb(for: prod)) * \(prod.displayPrice)")
                        .font(theme.fontTheme.toFont(.footnote))
                        .foregroundStyle(.secondary)
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
        }
    }
}
