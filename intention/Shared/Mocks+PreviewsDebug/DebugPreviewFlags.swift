//
//  DebugPreviewFlags.swift
//  intention
//
//  Created by Benjamin Tryon on 11/1/25.

import Foundation

@inline(__always)
var IS_PREVIEW: Bool {
    #if DEBUG
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] != nil
    #else
    return false
    #endif
}
