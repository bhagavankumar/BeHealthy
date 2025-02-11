import XCTest
@testable import YourAppName
import FirebaseAuth

class ChangePasswordViewTests: XCTestCase {
    var view: ChangePasswordView!
    
    override func setUp() {
        super.setUp()
        view = ChangePasswordView()
    }
    
    func testPasswordValidation() {
        view.oldPassword = "oldpass"
        view.newPassword = "newpass"
        view.confirmPassword = "wrongpass"
        
        view.changePassword()
        XCTAssertEqual(view.alertMessage, "New passwords do not match.")
    }
}