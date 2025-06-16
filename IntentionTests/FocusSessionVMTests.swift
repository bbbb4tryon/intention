//
//  FocusSessionVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 6/12/25.
//

import XCTest
@testable import intention

@MainActor
final class FocusSessionVMTests: XCTestCase {
    func testSubmitTileTrimsText() async throws {
        let vm = FocusSessionVM()
        await vm.startAppendTileSession()
        vm.tileText = "   Meditate"
        
        try await vm.submitTile()
        
        XCTAssertEqual(vm.tiles.count, 1)
        XCTAssertEqual(vm.tiles.first?.text, "Meditate")
    }
    
    func testSubmitEmptyTileThrows() async throws {
        let vm = FocusSessionVM()
        await vm.startAppendTileSession()
        vm.tileText = "   "
        
        do {
            try await vm.submitTile()
            XCTFail("Expected empty input to throw")
        } catch FocusSessionError.emptyInput {
            // ✅ expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
