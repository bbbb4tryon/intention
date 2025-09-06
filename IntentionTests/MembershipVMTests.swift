//
//  MembershipVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/7/25.
//

import XCTest
@testable import intention

@MainActor
final class MembershipVMTests: XCTestCase {
    func testPromptFlagWhenThresholdMet() {
        let vm = MembershipVM()
        vm.isMember = false
        vm.triggerPromptifNeeded(afterSessions: 2, threshold: 2)
        
        XCTAssertTrue(vm.shouldPrompt)
    }
}
