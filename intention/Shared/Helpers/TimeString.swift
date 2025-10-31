//
//  TimeString.swift
//  intention
//
//  Created by Benjamin Tryon on 10/31/25.
//

import Foundation

enum TimeString {
    /// Formats seconds as mm:ss using Swift FormatStyle.
    static func mmss(_ seconds: Int) -> String {
        if #available(iOS 15.0, *) {
            return Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
        } else {
            let f = DateComponentsFormatter()
            f.allowedUnits = [.minute, .second]
            f.unitsStyle = .positional
            f.zeroFormattingBehavior = [.pad]
            return f.string(from: TimeInterval(seconds)) ?? "00:00"
        }
    }
}

enum PercentString {
    /// Formats a 0.0...1.0 ratio as whole-percent (e.g., 0.87 -> "87%").
    static func whole(_ ratio: Double) -> String {
        ratio.formatted(.percent.precision(.fractionLength(0)))
    }
}
