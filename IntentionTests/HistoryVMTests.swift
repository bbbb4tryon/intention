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
        let vm = HistoryVM(persistence: TestPersistence(), userService: userService)
        vm.ensureDefaultCategory(userService: userService)
        
        let found = vm.categories.contains { $0.id == userService.defaultCategoryID }
        XCTAssertTrue(found, "Default/Archive category was not inserted")
    }
    
    func testArchiveCategoryInsertion() {
        let userService = UserService()
        let vm = HistoryVM(persistence: TestPersistence(), userService: userService)
        vm.ensureArchiveCategory(userService: userService)
        
        let found = vm.categories.contains { $0.id == userService.archiveCategoryID }
        XCTAssertTrue(found, "Default category was not inserted")
    }
    
    func testAddCateogryAndPersist() async throws {
        let savedExpectation = expectation(description: "Saved")
        let persistence = TestPersistence(didSave: savedExpectation)
        let userService = UserService()
        let vm = HistoryVM(persistence: persistence, userService: userService)
        
        // Creates a category
        let newCateogory = CategoriesModel(id: UUID(), persistedInput:  "Work", tiles: [])
        vm.categories.append(newCateogory)
        
        // Trigger a save
        try await persistence.saveHistory(vm.categories, to: "categories data")
        
        // Load it back
        let loaded: [CategoriesModel]? =
            try await persistence.loadHistory([CategoriesModel].self, from: "categories data")
        
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.persistedInput, "Work")
        
        await fulfillment(of: [savedExpectation], timeout: 1.0)
    }
}
