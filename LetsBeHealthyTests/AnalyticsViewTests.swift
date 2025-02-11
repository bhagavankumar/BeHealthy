import XCTest
@testable import YourAppName
import HealthKit

class AnalyticsViewTests: XCTestCase {
    var analyticsView: AnalyticsView!
    var mockHealthStore: HKHealthStore!

    override func setUp() {
        super.setUp()
        analyticsView = AnalyticsView()
        mockHealthStore = HKHealthStore()
        analyticsView.healthStore = mockHealthStore
    }

    func testFetchStepData() async {
        let expectation = XCTestExpectation(description: "Fetch step data")
        
        // Mock HealthKit response
        analyticsView.fetchStepData()
        
        // Validate after async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertGreaterThan(self.analyticsView.dailySteps, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
    }
}