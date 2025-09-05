//
//  Sheet.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//
//
//import Foundation
import SwiftUI
//
//// Define `Sheet` *inside* of `State`
//enum Sheet: Equatable {
//    case none
//    case edit
//    case new
//}
//
//// Adds `currentSheet` to the state
//var currentSheet: Sheet = .none
//
//// Adds a helper - cleaner binding
//var isSheetPresented: Bool {
//    currentSheet != .none
//}
//
//// Adds `setSheet` action
//case setSheet(State.Sheet)

//
//2. should Stats be separate from session and membership and anything non-program and user-interaction logic that are (maybe?) in other .swift files? Explain pros and cons.


//MembershipError    case purchaseFailed, restoreFailed, invalidCode, networkError, appEnvironmentFail
//}

struct MembershipSheetV: View {
    @EnvironmentObject var viewModel: MembershipVM
    @EnvironmentObject var theme: ThemeManager
    
    @State private var isFavorite = false
    @State var codeInput: String = ""
    
    private var p: ThemePalette { theme.palette(for: .membership) }
    private var T: (String, TextRole) -> LocalizedStringKey {
        { key, role in LocalizedStringKey(theme.styledText(key, as: role, in: .history))    }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                Page {
                    theme.styledText("Unlock Unlimited Focus", as: .section, in: .membership)
//                        .multilineTextAlignment(.center)
                        .friendlyHelper()
                    
                    theme.styledText("You’ve completed your free sessions. For just 20–30¢ a day, unlock unlimited focus sessions, detailed stats, more categories, and full customization. Build momentum, track progress, and work with intention — while helping us keep the lights on, the mortgage paid, and the dog well-fed. Your focus fuels our future. Thank you.", as: .body, in: .membership)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.palette(for: .membership).textSecondary)
//                    
//                    theme.styledText("By continuing, you agree to our Terms and Privacy.", as: .caption, in: .membership))
//                        .font(theme.fontTheme.toFont(.footnote))
//                        .foregroundStyle(.secondary)
//                        .padding(.bottom, 8)
                    
                    if viewModel.isMember {
                        Label(T("Member! You're supporting us!", .label), systemImage: "star")
                            .symbolBounceIfAvailable()
                    } else {
                        Button(T("Upgrade Membership", .action)) {
                            Task {
                                do {
                                    try await viewModel.purchaseMembershipOrPrompt()
                                } catch {
                                    debugPrint("[viewModel.purchaseMembershipOrPrompt] error: ", error)
                                    viewModel.setError(error)                /// Shows ErrorOverlay
                                }
                            }
                        }
                        .primaryActionStyle(screen: .membership)
                        
                        Button(T("Restore Purchases", .label)) {
                            Task {
                                do {
                                    try await viewModel.restoreMembershipOrPrompt()
                                } catch {
                                    debugPrint("[viewModel.restoreMembershipOrPrompt] error:", error)
                                    viewModel.setError(error)                /// Shows ErrorOverlay
                                    // _ = await MainActor.run {  MembershipError.restoreFailed }
                                }
                            }
                        }
                        .secondaryActionStyle(screen: .membership)
                        
                        
                        
                        if !AppEnvironment.isAppStoreReviewing {
                            Divider()
                            Button(T("Visit Website", .section)) {
                                Task {
                                    if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                        await UIApplication.shared.open(url)
                                    } else {
                                        debugPrint("[MembershipSheetV.isAppStoreReviewing] bad URL" )
                                        viewModel.setError(MembershipError.appEnvironmentFail)   /// Shows ErrorOverlay
                                    }
                                }
                            }
                            .primaryActionStyle(screen: .membership)
                            .font(.footnote)
                            .underline()
                        
                        VStack(spacing: 12) {
                            Button(T("Enter Membership Code", .label) {
                                viewModel.showCodeEntry = true
                            }
                            .primaryActionStyle(screen: .membership)
                            
                            if viewModel.showCodeEntry {
                                VStack(spacing: 8) {
                                    TextField(T("Enter code", .section), text: $codeInput)
                                        .textFieldStyle(.roundedBorder)
                                        .autocapitalization(.allCharacters)
                                        .disableAutocorrection(true)
                                    
                                    Button(T("Redeem", .label)) {
                                        Task {
                                            do {
                                                try await viewModel.verifyCode(codeInput)
                                            } catch {
                                                debugPrint("[MembershipSheetV.showCodeEntry] error: ", error )
                                                viewModel.setError(error)                /// Shows ErrorOverlay
                                            }
                                        }
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
