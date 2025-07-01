//
//  ErrorOverlay.swift
//  intention
//
//  Created by Benjamin Tryon on 7/1/25.
//

import SwiftUI

struct ErrorOverlay: View {
    let error: Error
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            
            Text("Something went wrong ⚠")
                .font(.title2)
                .bold()
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("dismiss", action: dismissAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}
