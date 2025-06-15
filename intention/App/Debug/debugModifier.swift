//
//  debugModifier.swift
//  intention
//
//  Created by Benjamin Tryon on 6/13/25.
//
import SwiftUI

// look in Utilities folder for this in action - this is a VISUAL modifier
extension View {
    func debugModifier<T: View>(_ modifier: (Self) -> T) -> some View {
        #if DEBUG
        return modifier(self)
        #else
        return self
        #endif
    }
}


