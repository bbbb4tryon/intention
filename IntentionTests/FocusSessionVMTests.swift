//
//  FocusSessionVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 6/12/25.
//
//
//import XCTest
//@testable import intention
//
//@MainActor
//final class FocusSessionVMTests: XCTestCase {
//    func testAddTileLogic() async throws {
//        let vm = FocusSessionVM(previewMode: false)
//        vm.tileText = "[FocusSessionVMTests.testAddTileLogic]"
//        
//        try await vm.addTileAndPrepareForSession()
//        
//        XCTAssertEqual(vm.tiles.count, 1)
//        XCTAssertEqual(vm.tiles.first?.text, "[FocusSessionVMTests.testAddTileLogic]")
//    }
//    
//    func testAddTileFailsIfEmpty() async {
//        let vm = FocusSessionVM()
//        vm.tileText = "     "
//        do {
//            try await vm.addTileAndPrepareForSession()
//            XCTFail("Should throw and emptyInput error")
//        } catch FocusSessionError.emptyInput {
//            /// success
//        } catch {
//            XCTFail("[FocusSessionVMTests.testAddTileLogic] Unexpected error: \(error)")
//        }
//    }
//}
