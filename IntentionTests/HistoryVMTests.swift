//
//  HistoryVMTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 8/7/25.
//

import XCTest
@testable import intention

@MainActor
final class HistoryVMTests: XCTestCase {
    func testDefaultCategoryInsertion() {
        let userService = UserService()
        let vm = HistoryVM()
        vm.ensureDefaultCategory(userService: userService)
        
        let found = vm.categories.contains { $0.id == userService.defaultCategoryID }
        XCTAssertTrue(found, "Default category was not inserted")
    }
}
