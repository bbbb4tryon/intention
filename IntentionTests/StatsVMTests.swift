//
//  StatsVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/7/25.
//

import XCTest
@testable import intention

@MainActor
final class StatsVMTests: XCTestCase {
    func testSessionLoggingUpdatesTotal() async {
        let vm = StatsVM(persistence: PersistenceActor())
        let session = CompletedSession(date: .now, tileTexts: ["Task 1", "Task 2"], recalibration: .breathing)
        
        vm.logSession(session)
        XCTAssertEqual(vm.totalCompletedIntentions, 2)
    }
}
