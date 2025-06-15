//
//  RecalibrationTheme.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import SwiftUI

enum RecalibrationTheme: String {
    case balancing, breathing
    
    var displayName: String {
        switch self {
        case .balancing: return "Stand on one foot until you tip over,then switch, then repeat. Made more mentally involved by closing one or both eyes."
        case .breathing: return "Close your eyes and become aware of your breathing. Focus your attention on your stomach. Four a count of four seconds, pulling your inhale down from your nose into your belly, pause for four seconds, then, for four seconds, push your exhale out of your mouth. Pause for four seconds, repeat."
        }
    }
}


