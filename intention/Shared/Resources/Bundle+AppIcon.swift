//
//  AppIcon.swift
//  intention
//
//  Created by Benjamin Tryon on 6/5/25.
//

import SwiftUI
import UIKit

extension Bundle {
    var appIconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
    
    // Convenience key/computed property to load the app icon (as a UIImage)
    var appIcon: UIImage? {
        guard let appIconFileName = appIconFileName else { return nil }
        return UIImage(named: appIconFileName)      // already GETS and returns the image... do NOT need map
    }
//    don't need the flatMap and map chain in the View's body because the intermediate optional states are already handled by your appIcon computed property
}
