//
//  StatsVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/7/25.
//
//
//import XCTest
//@testable import intention
//
//@MainActor
//final class StatsVMTests: XCTestCase {
//    func testSessionLoggingUpdatesTotal_andPersists() async throws {
//        let savedExpectation = expectation(description: "Saved")
//        let persistence = InMemoryPersistence(didSave: savedExpectation)
//        let vm = StatsVM(persistence: persistence)
//        
//        vm.logSession(CompletedSession(date: .now, tileTexts: ["A", "B"], recalibration: .breathing))
//        
//        XCTAssertEqual(vm.totalCompletedIntentions, 2)
//        await fulfillment(of: [savedExpectation], timeout: 1.0)
//    }
//}
