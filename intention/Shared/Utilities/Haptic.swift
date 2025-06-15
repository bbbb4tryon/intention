//
//  Haptic.swift
//  intention
//
//  Created by Benjamin Tryon on 6/14/25.
//

import Foundation
import UIKit

enum Haptic {
    static func notifyDone() {
        // long, long, short
        for delay in [0.0, 1.0, 2.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }
    
    static func notifySwitch() {
        // short, short
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
