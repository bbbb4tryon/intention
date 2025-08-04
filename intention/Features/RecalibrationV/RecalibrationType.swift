//
//  RecalibrationType.swift
//  intention
//
//  Created by Benjamin Tryon on 7/22/25.
//

import SwiftUI

// Authoritiative model
enum RecalibrationType: String, CaseIterable, Hashable, Codable {
    case breathing
    case balancing

    var label: String {
        switch self {
        case .balancing: return "Balancing Reset"
        case .breathing: return "Breathing Reset"
        }
    }

    var instructions: [String] {
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

    var iconName: String {
        switch self {
        case .balancing: return "figure.stand"
        case .breathing: return "lungs.fill"
        }
    }
}
