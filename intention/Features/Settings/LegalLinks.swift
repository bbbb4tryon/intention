//
//  LegalLinks.swift
//  intention
//
//  Created by Benjamin Tryon on 8/20/25.
//

import SwiftUI

struct LegalLinks: View {
    @EnvironmentObject var theme: ThemeManager
    
    let termsURL = URL(string: "https://argonnesoftware.com/terms")!
    let privacyURL = URL(string: "https://argonnesoftware.com/privacy")!
    var body: some View {
        Text("By continuing, you agree to our ")
        + Text("[Terms](https://argonnesoftware.com/terms)")
        + Text(" and ")
        + Text("[Privacy](https://argonnesoftware.com/privacy)")
//            .foregroundStyle(.secondary)        //FIXME: Add foregroundStyle to Available
    }
}
