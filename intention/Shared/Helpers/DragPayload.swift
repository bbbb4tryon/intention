//
//  DragPayload.swift
//  intention
//
//  Created by Benjamin Tryon on 9/20/25.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct DragPayload: Codable, Hashable, Transferable {
    let tile: TileM
    let sourceCategoryID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
