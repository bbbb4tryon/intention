//
//  FocusSessionFlowUITests.swift
//  FocusSessionFlowUITests
//
//  Created by Benjamin Tryon on 8/7/25.
//

import XCTest

final class FocusSessionFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testCompleteTwoIntentionsSession() throws {
        app.tabBars.buttons.element(boundBy: 0).tap()       // Focus tab button
        
        let input = app.textFields["Enter what you intent to do [FocusSessionFlowUITests.testCompleteTwoIntentionsSession]"]
        input.tap()
        input.typeText("First task\n")
        
        sleep(1)
        
        input.tap()
        input.typeText("Second task\n")
        
        let beginButton = app.buttons["Begin"]
        XCTAssertTrue(beginButton.waitForExistence(timeout: 2))
        beginButton.tap()
        
        // Simulate session completion or shorten timer in debug builds
        sleep(3)        // Replace w `app.advanceTimerIfPossible()` if you have debug triggers
        
        // Verify recalibrate modal exists
        XCTAssert(app.staticTexts["Recalibrate Modal present?"].waitForExistence(timeout: 5))
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
