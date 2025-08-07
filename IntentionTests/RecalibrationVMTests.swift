//
//  RecalibrationVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/7/25.
//

import XCTest
@testable import intention

@MainActor
final class RecalibrationVMTests: XCTestCase {
    func testStartRecalibrationSetsInstruction() {
        let vm = RecalibrationVM()
        vm.start(mode: .breathing)
        
        XCTAssertEqual(vm.instruction, "Inhale")
        XCTAssertEqual(vm.phase, .running)
    }
}
