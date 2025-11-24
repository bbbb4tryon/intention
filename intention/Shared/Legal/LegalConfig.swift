//
//  LegalConfig.swift
//  intention
//
//  Created by Benjamin Tryon on 10/22/25.
//

import SwiftUI
import UIKit

// MARK: - File config (do NOT include .md)
/// Gate logic checks acceptedVersion < currentVersion. After you ship an update with currentVersion = 2, any user who previously accepted version 1 will see the legal sheet again on next launch.
enum LegalConfig {
    static let currentVersion = 1               // "bumping" this (1 to 2 to 3)
    static let termsFile   = "termsmarkdown"
    static let privacyFile = "privacymarkdown"
    static let medicalFile = "medicalmarkdown"
}
