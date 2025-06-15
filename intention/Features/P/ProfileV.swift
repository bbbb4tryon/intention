//
//  ProfileV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

//  User identity, history
struct ProfileV: View {
    @AppStorage("colorTheme") private var colorTheme: AppColorTheme = .default
    @AppStorage("fontTheme") private var fontTheme: AppFontTheme = .serif
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .profile)
        
        NavigationView {
//        FixedHeaderLayoutV {
//            Text.pageTitle("Profile")
//        } content: {
            VStack(spacing:20){
                Text("You")
                    .styledTitle(font: fontTheme, color: palette.text)

                Section(header: Text("History")){
                    ForEach(0..<12) { i in
                        Text("\(i)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.accent.ignoresSafeArea())
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .padding()
        .font(fontTheme.toFont(.title3))    // default body styling
        .foregroundStyle(palette.text)
        .background(palette.background.ignoresSafeArea())
    }
}

#Preview {
    ProfileV()
}
/*
 Background: .intMint (or intTan)

 Title text: .intBrown

 Buttons: .intMoss

 Highlight badges: .intSeaGreen
 */
