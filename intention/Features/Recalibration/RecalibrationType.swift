//
//  RecalibrationMode.swift
//  intention
//
//  Created by Benjamin Tryon on 7/22/25.
//

import SwiftUI

// Authoritiative model - Operation + duration, View can request preset cleanly
/// Role-only; Durations live in the VM's config

enum RecalibrationMode: String, Hashable, Codable, CaseIterable {
    case balancing
    case breathing
    
    var label: String {
        switch self {
        case .balancing: return "Balancing Reset"
        case .breathing: return "Breathing Reset"
        }
    }
    
    var iconName: String {
        switch self {
        case .balancing: return "figure.stand"
        case .breathing: return "lungs.fill"
        }
    }
    
        var instructions: [String] {
            switch self {
            case .balancing:
                /// 4 minutes, switch every minute
                return [
                    "Stand on one foot.",
                    "Switch feet, every minute",
                    "Level up: close eyes and repeat."
                ]
            case .breathing:
                /// 6-3, 6-3
                return [
                    "Inhale 6 sec, hold 3 sec.",
                    "Exhale 6 sec, hold 3 sec.",
                    "Repeat until timer ends."
                ]
            }
        }
}

