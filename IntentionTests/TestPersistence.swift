//
//  TestPersistence.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/7/25.
//

import Foundation
import XCTest
@testable import intention

/// In-memory persistence for unit tests
final actor TestPersistence: Persistence {
    private var store: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private let didSave: XCTestExpectation?
    
    init(didSave: XCTestExpectation? = nil) {
        self.didSave = didSave
    }
    
    func saveHistory<T: Codable>(_ object: T, to key: String) async throws {
        store[key] = try encoder.encode(object)
        didSave?.fulfill()
    }
    
    func loadHistory<T: Codable>(_ type: T.Type, from key: String) async throws -> T? {
        guard let data = store[key] else { return nil }
        return try decoder.decode(type, from: data)
    }
    
    func clear(_ key: String) async {
        store.removeValue(forKey: key)
    }
}
