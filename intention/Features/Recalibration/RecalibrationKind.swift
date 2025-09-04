//
//  RecalibrationKind.swift
//  intention
//
//  Created by Benjamin Tryon on 9/3/25.
//


import Foundation

enum RecalibrationKind: String, Codable, Hashable {
    case breathing, balancing
}

struct RecalibrationRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let kind: RecalibrationKind
    let durationSeconds: Int
}
