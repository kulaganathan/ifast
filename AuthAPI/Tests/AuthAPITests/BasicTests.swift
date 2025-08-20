import XCTest
@testable import AuthAPI

final class BasicTests: XCTestCase {
    func testInit() {
        _ = APIClient()
        _ = KeychainTokenStore()
    }
}


