import XCTest
@testable import YourAppName

class GoalViewTests: XCTestCase {
    var goalView: GoalView!
    
    override func setUp() {
        super.setUp()
        goalView = GoalView()
    }
    
    func testGoalSaving() {
        goalView.dailyGoal = 10000
        goalView.saveGoal()
        
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "dailyGoal"), 10000)
    }
}