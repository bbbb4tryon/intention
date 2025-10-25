//
//  DevButtonsInSettings.swift
//  intention
//
//  Created by Benjamin Tryon on 10/24/25.
//

import Foundation

extension Notification.Name {
    static let devOpenRecalibration      = Notification.Name("ShowRecalibrationToDebug")
    static let devOpenOrganizerOverlay   = Notification.Name("ShowOrganizerOverlayToDebug")
    static let devOpenMembership         = Notification.Name("ShowMembershipToDebug")
    static let devOpenErrorOverlay       = Notification.Name("ShowSampleErrorToDebug")
}

// Helper struct for keys when passing data
enum DebugNotificationKey {
    static let errorTitle = "errorTitleKey"
    static let errorMessage = "errorMessageKey"
}
