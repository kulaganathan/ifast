import Foundation

public final class UserAPI: @unchecked Sendable {
    private let client: APIClient
    public init(client: APIClient) { self.client = client }
    
    public func getCurrentUser() async throws -> UserResponse {
        try await client.request("/api/users/me", as: UserResponse.self)
    }
    
    public func getUserById(_ id: Int64) async throws -> UserResponse {
        try await client.request("/api/users/\(id)", as: UserResponse.self)
    }
    
    public func register(_ request: UserRegistrationRequest) async throws -> UserResponse {
        try await client.request("/api/users/register", method: "POST", body: request, requiresAuth: false, as: UserResponse.self)
    }
    
    public func updateUserRoles(userId: Int64, roles: [String]) async throws -> String {
        try await client.request("/api/users/\(userId)/roles", method: "PUT", body: roles, as: String.self)
    }
    
    public func updateUserProfile(userId: Int64, firstName: String, lastName: String) async throws -> UserResponse {
        try await client.request("/api/users/\(userId)/profile", method: "PUT", query: [
            URLQueryItem(name: "firstName", value: firstName),
            URLQueryItem(name: "lastName", value: lastName)
        ], as: UserResponse.self)
    }
    
    public func lockUser(userId: Int64) async throws -> String {
        try await client.request("/api/users/\(userId)/lock", method: "POST", as: String.self)
    }
    public func unlockUser(userId: Int64) async throws -> String {
        try await client.request("/api/users/\(userId)/unlock", method: "POST", as: String.self)
    }
    public func enableUser(userId: Int64) async throws -> String {
        try await client.request("/api/users/\(userId)/enable", method: "POST", as: String.self)
    }
    public func disableUser(userId: Int64) async throws -> String {
        try await client.request("/api/users/\(userId)/disable", method: "POST", as: String.self)
    }
    public func deleteUser(userId: Int64) async throws -> String {
        try await client.request("/api/users/\(userId)", method: "DELETE", as: String.self)
    }
}


