//
//  debugAction.swift
//  intention
//
//  Created by Benjamin Tryon on 6/13/25.
//

import SwiftUI

//  append a call at the end of view { }.here declaration, just like any other modifier
//      only actually prints a value within debug builds if used as `.debugPrint()`
extension View {
    func debugAction(_ closure: () -> Void) -> Self {
    #if DEBUG
    closure()
    #endif
        
        return self
    }
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
