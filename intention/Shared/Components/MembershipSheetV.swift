//
//  Sheet.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//
//
//import Foundation
//import SwiftUI
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
//
//2. should Stats be separate from session and membership and anything non-program and user-interaction logic that are (maybe?) in other .swift files? Explain pros and cons.

//import SwiftUI
//
//struct MembershipSheetV: View {
//    var body: some View {
//        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
//    }
//}
//
//#Preview {
//    MembershipSheetV()
//        .environmentObject(MembershipVM())
//}
