//
//  ProgressOverlay.swift
//  intention
//
//  Created by Benjamin Tryon on 9/20/25.
//

/*
 Use anywhere:
 @State private var isBusy = false body: some View {... .progressOverlay($isBusy, text: "Loading..."}
 func someLongAction() { isBusy = true;  Task { defer [ isBusy = false } try? await Task // do work } }
 */
import SwiftUI

struct ProgressOverlay: ViewModifier {
    @Binding var isPresented: Bool
    var text: String = "Loading..."
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                Color.black.opacity(0.2).ignoresSafeArea()
                VStack(spacing: 10){
                    ProgressView()
                    Text(text).font(.footnote).foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(radius: 3, y: 1)
                .transition(.opacity)
            }
        }
    }
}
extension View {
    func progressOverlay(_ isPresented: Binding<Bool>, text: String = "Loading...") -> some View {
        modifier(ProgressOverlay(isPresented: isPresented, text: text))
    }
}
