//
//  RecalibrationTheme.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

enum RecalibrationTheme: String, CaseIterable {
    case balancing, breathing
    
    var displayName: String {
        switch self {
        case .balancing: return "Balancing Reset"
        case .breathing: return "Breathing Reset"
        }
    }
    
    var instruction: [String] {
        switch self {
        case .balancing:
            return [
                "Stand on one foot.",
                "Tip over? Switch feet.",
                "Eyes closed = expert mode.",
                "Switch every minute!"
            ]
        case .breathing:
            return [
                "Inhale for 4 seconds.",
                "Pause for 4 seconds.",
                "Exhale for 4 seconds.",
                "Pause. Repeat for 4 minutes."
            ]
        }
    }
    
    var imageName: String {
        switch self {
        case .balancing: return "figure.stand"
        case .breathing: return "lungs.fill"
        }
    }
}
