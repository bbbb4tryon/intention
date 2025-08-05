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
struct MembershipSheetV: View {
    @EnvironmentObject var membershipVM: MembershipVM
    @EnvironmentObject var theme: ThemeManager
    
    @State private var isFavorite = false
    @State var codeInput: String = ""
    
    var body: some View {
        VStack(spacing: 24){
            Text("Unlock Unlimited Focus")
                .font(theme.fontTheme.toFont(.title2))
                .multilineTextAlignment(.center)
            
            Text("You've completed your free sessions. For 20 - 30 cents a day, gain unlimited sessions, more statistics, more categories, editable categories and so much more. Plus, you're supporting our time to build more features, to pay the mortgage, to buy dog food! Thank you.")
                .multilineTextAlignment(.center)
                .font(theme.fontTheme.toFont(.body))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
            
            if membershipVM.isMember {
                Label("Member! You're supporting us!", systemImage: "star")
                    .symbolEffect(.bounce)
            } else {
                Button("Upgrade Membership") {
                    Task {
                        do {
                            try await membershipVM.purchaseMembershipOrPrompt()
                        } catch {
                            debugPrint("[MembershipVM.purchaseMembershipOrPrompt] error: ", error)
                            await MainActor.run { MembershipError.purchaseFailed }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Restore Purchases") {
                    Task {
                        do {
                            try! await membershipVM.restoreMembershipOrPrompt()
                        } catch {
                            debugPrint("[MembershipVM.restoreMembershipOrPrompt] error:", error)
                            await MainActor.run {  MembershipError.restoreFailed }
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                
                if !AppEnvironment.isAppStoreReviewing {
                    Divider()
                    Button("Visit Website") {
                        Task {
                            do {
                                if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                    await UIApplication.shared.open(url)
                                }
                            } catch {
                                debugPrint("[MembershipSheetV.isAppStoreReviewing] error: ", error )
                                await MainActor.run { MembershipError.appEnvironmentFail }
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
                                        await membershipVM.verifyCode(codeInput)
                                    } catch {
                                        debugPrint("[] error: ", error )
                                        await MainActor.run { MembershipError.invalidCode
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                    } else {
//                        break
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    MembershipSheetV()
        .environmentObject(MembershipVM())
}
