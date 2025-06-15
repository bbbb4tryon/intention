//
//  debugVisualizer.swift
//  intention
//
//  Created by Benjamin Tryon on 6/13/25.
//

import SwiftUI

extension View {
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        debugModifier {
            $0.border(color, width: width)
        }
    }
    
    func debugBackground(_ color: Color = .red) -> some View {
        debugModifier {
            $0.background(color)
        }
    }
}

/*
 
 Text(viewModel.formattedDate)
                .debugBackground(.green)
 or
 
 VStack {
        // code
    }
    .debugBorder()
 */
