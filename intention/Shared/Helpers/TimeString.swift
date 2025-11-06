//
//  TimeString.swift
//  intention
//
//  Created by Benjamin Tryon on 10/31/25.
//

import Foundation

enum TimeString {
    /// Formats seconds as "MM:SS". Clamps negatives to 0.
    @inlinable
    static func mmss(_ seconds: Int) -> String {
        // any negative clamps to `0`; `0` stays `0`; positive values are passed through
        let s: Int = max(0, seconds)
        let m: Int = s / 60
        let r: Int  = s % 60
        // String(format:) is fast and locale-agnostic for this spec.
        return String(format: "%02d:%02d", m, r)
    }
//    static func mmss(_ seconds: Int) -> String {
//        if #available(iOS 15.0, *) {
//            return Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
//        } else {
//            let f = DateComponentsFormatter()
//            f.allowedUnits = [.minute, .second]
//            f.unitsStyle = .positional
//            f.zeroFormattingBehavior = [.pad]
//            return f.string(from: TimeInterval(seconds)) ?? "00:00"
//        }
//    }
}

enum PercentString {
    /// Formats a 0.0...1.0 ratio as whole-percent (e.g., 0.87 -> "87%").
    static func whole(_ ratio: Double) -> String {
        ratio.formatted(.percent.precision(.fractionLength(0)))
    }
}
