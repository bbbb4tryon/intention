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
    @EnvironmentObject var membershipVM: MembershipVM
    @EnvironmentObject var theme: ThemeManager
    
    @State private var isFavorite = false
    @State var codeInput: String = ""
    
    var body: some View {
        ZStack {
        VStack(spacing: 24){
            Text("Unlock Unlimited Focus")
                .font(theme.fontTheme.toFont(.title2))
                .multilineTextAlignment(.center)
            
            Text("You’ve completed your free sessions. For just 20–30¢ a day, unlock unlimited focus sessions, detailed stats, more categories, and full customization. Build momentum, track progress, and work with intention — while helping us keep the lights on, the mortgage paid, and the dog well-fed. Your focus fuels our future. Thank you.")
                .multilineTextAlignment(.center)
                .font(theme.fontTheme.toFont(.body))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
            
            if membershipVM.isMember {
                Label("Member! You're supporting us!", systemImage: "star")
                    .symbolBounceIfAvailable()
            } else {
                Button("Upgrade Membership") {
                    Task {
                        do {
                            try await membershipVM.purchaseMembershipOrPrompt()
                        } catch {
                            debugPrint("[MembershipVM.purchaseMembershipOrPrompt] error: ", error)
                            membershipVM.setError(error)                /// Shows ErrorOverlay
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Restore Purchases") {
                    Task {
                        do {
                            try await membershipVM.restoreMembershipOrPrompt()
                        } catch {
                            debugPrint("[MembershipVM.restoreMembershipOrPrompt] error:", error)
                            membershipVM.setError(error)                /// Shows ErrorOverlay
                            // _ = await MainActor.run {  MembershipError.restoreFailed }
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                
                
                if !AppEnvironment.isAppStoreReviewing {
                    Divider()
                    Button("Visit Website") {
                        Task {
                            if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                await UIApplication.shared.open(url)
                            } else {
                                debugPrint("[MembershipSheetV.isAppStoreReviewing] bad URL" )
                                membershipVM.setError(MembershipError.appEnvironmentFail)   /// Shows ErrorOverlay
                            }
                        }
                    }
                    .mainActionStyle(screen: .homeActiveIntentions)
                    .font(.footnote)
                    .underline()
                }
                
                VStack(spacing: 12) {
                    Button("Enter Membership Code") {
                        membershipVM.showCodeEntry = true
                    }
                    .mainActionStyle(screen: .homeActiveIntentions)
                    
                    if membershipVM.showCodeEntry {
                        VStack(spacing: 8) {
                            TextField("Enter code", text: $codeInput)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                            
                            Button("Redeem") {
                                Task {
                                    do {
                                        try await membershipVM.verifyCode(codeInput)
                                    } catch {
                                        debugPrint("[MembershipSheetV.showCodeEntry] error: ", error )
                                        membershipVM.setError(error)                /// Shows ErrorOverlay
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
        }
        
        /// Overlay shown if there is a lastError
        if let error = membershipVM.lastError {
            ErrorOverlay(error: error) {
                membershipVM.setError(nil)  /// Dismiss
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(1)
        }
    }
}
}

