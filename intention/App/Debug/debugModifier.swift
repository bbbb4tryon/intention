//
//  debugModifier.swift
//  intention
//
//  Created by Benjamin Tryon on 6/13/25.
//
import SwiftUI

extension View {
    @ViewBuilder
    func debugModifier<T: View>(_ modifier: (Self) -> T) -> some View {
        #if DEBUG
        modifier(self)
        #else
        self
        #endif
    }
    //  append a call at the end of view { }.here declaration, just like any other modifier
    //      only actually prints a value within debug builds if used as `.debugPrint()`
    @discardableResult
        func debugAction(_ closure: () -> Void) -> Self {
        #if DEBUG
        closure()
        #endif
            return self
        }

    /*
     example:
     extension View {
         func debugPrint(_ value: Any) -> Self {
             debugAction { print(value) }
         }
     }

     struct EventView: View {
         @ObservedObject var viewModel: EventViewModel

         var body: some View {
             VStack {
                 ...
             }
             .debugPrint(viewModel.bannerImage.size)
         }
     }
     */

    // Convenience wrappers
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        debugModifier { $0.border(color, width: width) }
    }
    
    func debugBackground(_ color: Color = .red) -> some View {
        debugModifier { $0.background(color) }
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



