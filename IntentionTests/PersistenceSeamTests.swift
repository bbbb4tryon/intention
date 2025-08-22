//
//  PersistenceSeamTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/20/25.
//

import XCTest
@testable import intention

final class PersistenceSeamTests: XCTestCase {
    
    private struct Note: Codable, Equatable { let id: Int; let text: String }
    
    func test_read_clear_roundTrip() async throws {
        let fake = InMemoryPersistence()
        let key = "test.notes"
        let sample = [Note(id: 1, text: "Test"), Note(id: 2, text: "World")]
        
        try await fake.write(sample, to: key)
            let loaded: [Note]? = try await fake.readIfExists([Note].self, from: key)
            XCTAssertEqual(loaded, sample)
        
        await fake.clear(key)
        let afterClear: [Note]? = try await fake.readIfExists([Note].self, from: key)
        XCTAssertNil(afterClear)
        }
    
    func test_write_fulfillsExpectation() async throws {
        let exp = expectation(description: "didSave")
        let fake = InMemoryPersistence(didSave: exp)
        try await fake.write(Note(id: 1, text: "x"), to: "k")
        await fulfillment(of: [exp], timeout: 1.0)
    }
}
