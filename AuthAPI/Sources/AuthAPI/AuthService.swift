import Foundation

public final class AuthService: @unchecked Sendable {
    private let client: APIClient
    private let tokenStore: TokenStore
    
    public init(client: APIClient, tokenStore: TokenStore = KeychainTokenStore()) {
        self.client = client
        self.tokenStore = tokenStore
    }
    
    // MARK: Auth flows
    public func login(username: String, password: String) async throws {
        // Assuming a login endpoint exists although not present in the spec.
        // Replace with actual when added to the spec.
        struct LoginRequest: Codable { let username: String; let password: String }
        let tokenString: String = try await client.request("/api/auth/login",
                                                          method: "POST",
                                                          body: LoginRequest(username: username, password: password),
                                                          requiresAuth: false,
                                                          as: String.self)
        // Expect tokenString contains accessToken|refreshToken (example); adapt as needed.
        let parts = tokenString.split(separator: "|")
        guard parts.count == 2 else { return }
        try tokenStore.save(TokenPair(accessToken: String(parts[0]), refreshToken: String(parts[1])))
    }
    
    public func refreshAccessTokenIfPossible() async throws {
        guard let tokens = try tokenStore.load() else { return }
        let newAccess: String = try await client.request("/api/auth/refresh",
                                                        method: "POST",
                                                        query: [URLQueryItem(name: "refreshToken", value: tokens.refreshToken)],
                                                        requiresAuth: false,
                                                        as: String.self)
        try tokenStore.save(TokenPair(accessToken: newAccess, refreshToken: tokens.refreshToken))
    }
    
    public func logout() async throws {
        _ = try await client.request("/api/auth/logout", method: "POST", requiresAuth: true, as: String.self)
        try? tokenStore.delete()
    }
}


