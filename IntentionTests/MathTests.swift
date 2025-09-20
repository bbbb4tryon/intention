//
//  MathTests.swift
//  IntentionTests
//
//  Created by Benjamin Tryon on 9/16/25.
//

//
//      Write the test (in the IntentionTests target)

//      Create IntentionTests/MathTests.swift (target membership: IntentionTests):
//  Create App/Helpers/Math.swift (target membership: your app target, not the test target):
//  App/Helpers/Math.swift
//  import Foundation

///   Minimal test seam: pure, deterministic
//  struct Math {
//      static func sum(_ a: Int, _ b: Int) -> Int { a + b }
//  }

@testable import intention
import XCTest

final class MathTests: XCTestCase {

   // naming pattern: test_Method_Scenario_Expected
    func test_Sum_TwoNumbers_ReturnSum() {
        XCTAssertEqual(Math.sum(1, 2), 3)
        
//        // Arrange (set up the needed objects)
//        let a = 1, b = 2
//        
//        // Act (run the method you want to test)
//        let result = Math.sum(a, b)
//        
//        // Assert (test that the behavior is as expected)
//        XCTAssertEqual(result, 3)
    }

}
