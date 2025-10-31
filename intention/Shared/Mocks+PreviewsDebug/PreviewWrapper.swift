////
////  PreviewWrapper.swift
////  intention
////
////  Created by Benjamin Tryon on 8/6/25.
////
//
//#if DEBUG
//import SwiftUI
//
//@MainActor
//struct PreviewWrapper<Content: View>: View {
//    let content: () -> Content
//
//    var body: some View {
//        content()
//            .environmentObject(PreviewMocks.prefs)
//            .environmentObject(PreviewMocks.membershipVM)
//            .environmentObject(PreviewMocks.history)        // some subviews use HistoryVM via EnvironmentObject
//            .environmentObject(PreviewMocks.stats)
//            .previewLayout(.sizeThatFits)                   // let content size itself
//            .frame(maxWidth: 430)                       // iPhone-ish width
//            
//    }
//}
//#endif
