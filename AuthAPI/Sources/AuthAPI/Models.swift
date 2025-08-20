import Foundation

public struct UserResponse: Codable, Sendable {
    public let id: Int64?
    public let username: String?
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let emailVerified: Bool?
    public let mfaEnabled: Bool?
    public let enabled: Bool?
    public let createdAt: Date?
    public let lastLoginAt: Date?
    public let roles: [String]?
}

public struct UserRegistrationRequest: Codable, Sendable {
    public let username: String
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    
    public init(username: String, email: String, password: String, firstName: String, lastName: String) {
        self.username = username
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
}

public struct MfaVerificationRequest: Codable, Sendable {
    public let code: String
    public init(code: String) { self.code = code }
}

public struct MfaSetupResponse: Codable, Sendable {
    public let secret: String?
    public let qrCodeUrl: String?
    public let backupCodes: [String]?
    public let message: String?
}

public struct TokenPair: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}


