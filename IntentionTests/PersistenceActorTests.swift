//
//  PersistenceActorTests.swift
//  intention
//
//  Created by Benjamin Tryon on 8/7/25.
//
//
import XCTest
@testable import intention

// an actor -- but not main-actor: test WITHOUT @MainActor and WITH `await`
final class PersistenceActorTests: XCTestCase {
    func testRoundTripSaveLoad() async throws {
        let p = PersistenceActor()
        let key = "test_key"
        let payload = ["a", "b", "c"]

        try await p.write(payload, to: key)
        let loaded: [String]? = try await p.readIfExists([String].self, from: key)
        XCTAssertEqual(loaded, payload)
    }
}

