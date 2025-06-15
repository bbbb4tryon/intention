//
//  FixedHeaderLayoutV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.
//

import SwiftUI

//Reusable layout with fixed header
struct FixedHeaderLayoutV<Header: View, Content: View>: View {
    let header: Header
    let content: Content
    
    init(@ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0){
        header
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .zIndex(1)
        
            ScrollView {
                VStack(spacing: Layout.verticalSpacing){
                    content
                }
                .padding(.top, 12)          // Spacing below header only
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, 32)
            }
        }
    }
}

