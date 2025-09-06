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
    
    func testGeneralCategoryInsertion() {
        let vm = HistoryVM(persistence: InMemoryPersistence())
        vm.ensureGeneralCategory(named: "General")
        
        let found = vm.categories.contains { $0.id == vm.generalCategoryID }
        XCTAssertTrue(found, "'General' category was not inserted")
        XCTAssertEqual(vm.categories.first(where: { $0.id == vm.generalCategoryID })?.persistedInput, "General")
    }
    
    func testArchiveCategoryInsertion() {
        let vm = HistoryVM(persistence: InMemoryPersistence())
        vm.ensureArchiveCategory(named: "Archive")
        
        let found = vm.categories.contains { $0.id == vm.archiveCategoryID }
        XCTAssertTrue(found, "'Archive' category was not inserted")
    }
    
    func testAddCateogryAndPersist() async throws {
        let savedExpectation = expectation(description: "Saved")
        let persistence = InMemoryPersistence(didSave: savedExpectation)
        let vm = HistoryVM(persistence: persistence)
        
        // Creates a category
        let newCateogory = CategoriesModel(id: UUID(), persistedInput:  "Some Category", tiles: [])
        vm.categories.append(newCateogory)
        
        // Trigger a save
        try await persistence.saveHistory(vm.categories, to: "categories data")
        
        // Load it back
        let loaded: [CategoriesModel]? =
            try await persistence.loadHistory([CategoriesModel].self, from: "categories data")
        
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.persistedInput, "Some Category")
        
        await fulfillment(of: [savedExpectation], timeout: 1.0)
    }
}
