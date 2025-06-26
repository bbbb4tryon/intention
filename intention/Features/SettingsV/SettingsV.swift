//
//  HistoryV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

// configuration, toggles, preferences

struct SettingsV: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        //        FixedHeaderLayoutV {
        //            Text.pageTitle("Settings")
        //        } content: {
        let palette = theme.palette(for: .settings)
        theme.styledText("Settings", as: .header, in: .settings)
        
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Toggle("Dark Mode", isOn: .constant(false))
                    Toggle("Enable Notification", isOn: .constant(true))
                    
                    //                Toggle("Haptics Only", isOn: $viewModel.hapticsOnly)
                    //                Toggle("Sound Enabled", isOn: $viewModel.soundEnabled)
                }
                //                .foregroundStyle(Color.intBrown)    // preferencestext color
                .tint(.intMint)     // toggle color
                
                Section(header: Text("App Color Theme")) {
                    Picker("Color Theme", selection: $theme.colorTheme) {
                        ForEach(AppColorTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Font Style")) {
                    Picker("Font Choice", selection: $theme.fontTheme) {
                        ForEach(AppFontTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsV_Previews: PreviewProvider  {
    static var previews: some View {
        SettingsV()
            .previewTheme()
    }
}

/*
 Background: .intTan

 Title text: .intBrown

 Toggle labels: .intGreen or .intMoss

 Destructive toggle: maybe .intBrown.opacity(0.7) if needed


 */
