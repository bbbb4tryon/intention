//
//  RecalibrationMode.swift
//  intention
//
//  Created by Benjamin Tryon on 7/22/25.
//

import SwiftUI

// Authoritiative model - Operation + duration, View can request preset cleanly
/// Role-only; Durations live in the VM's config

enum RecalibrationMode: Hashable, Codable, CaseIterable {     //FIXME: String, CaseIterable?
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
                return [
                    "Stand on one foot.",
                    "Switch every minute",
                    "Close eyes for expert mode.",
                ]
            case .breathing:
                return [
                    "Inhale 5 sec, hold 2 sec.",
                    "Exhale 5 sec, hold 2 sec.",
                    "Repeat until timer ends."
                ]
            }
        }
}


//enum RecalibrationMode: String, CaseIterable, Hashable, Codable {

