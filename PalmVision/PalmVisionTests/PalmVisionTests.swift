//
//  PalmVisionTests.swift
//  PalmVisionTests
//
//  Created by Katelyn Fritz on 6/24/23.
//

import XCTest
@testable import PalmVision

final class PalmVisionTests: XCTestCase {
    
    // Sample observations for testing
    var sampleObservations: [Observation] = [
        Observation(label: "healthy", confidence: 0.9, boundingBox: CGRect()),
        Observation(label: "healthy", confidence: 0.9, boundingBox: CGRect())
    ]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // Test the countLabel function
    func testCountLabel() {
        let analyze = Analysis(observations: sampleObservations)
        let labelCounts = analyze.countLabel(observations: sampleObservations)
        let expectedHealthyCount = 2
        XCTAssertEqual(labelCounts[.healthy]!, expectedHealthyCount, "Healthy count mismatch!")
        XCTAssertEqual(analyze.isHealthy(), true, "Healthy check mismatch!")
    }

    func testCountZeroLabel() {
        let obs: [Observation] = []
        let analyze = Analysis(observations: obs)
        XCTAssertEqual(analyze.isHealthy(), false, "Healthy check mismatch!")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
