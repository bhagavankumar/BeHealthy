import XCTest
@testable import YourAppName
import FirebaseAuth

class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthManager.shared
    }
    
    func testSignOut() {
        authManager.signOut()
        XCTAssertNil(authManager.appUser)
    }
    
    func testUserUpdateOnAuthChange() {
        let mockUser = MockFirebaseUser(displayName: "John Doe", email: "test@example.com")
        authManager.updateUser(from: mockUser)
        XCTAssertEqual(authManager.appUser?.firstName, "John")
    }
}

// Mock Firebase User
class MockFirebaseUser: FirebaseAuth.User {
    let mockDisplayName: String?
    let mockEmail: String?
    
    init(displayName: String?, email: String?) {
        self.mockDisplayName = displayName
        self.mockEmail = email
        super.init()
    }
    
    override var displayName: String? { mockDisplayName }
    override var email: String? { mockEmail }
}