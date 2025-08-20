import Foundation

struct APIConfig {
    // MARK: - Base Configuration
    
    /// Base URL for the authentication server
    static let baseURL = "http://localhost:8080"
    
    /// API version
    static let apiVersion = "v1"
    
    /// Timeout for network requests (in seconds)
    static let requestTimeout: TimeInterval = 30
    
    /// Maximum retry attempts for failed requests
    static let maxRetryAttempts = 3
    
    // MARK: - Authentication
    
    /// Token refresh threshold (in seconds before expiration)
    static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes
    
    /// Keychain service identifier
    static let keychainService = "iFast.AuthAPI.TokenStore"
    
    /// Keychain account identifier
    static let keychainAccount = "default"
    
    // MARK: - Endpoints
    
    struct Endpoints {
        static let login = "/api/auth/login"
        static let logout = "/api/auth/logout"
        static let refresh = "/api/auth/refresh"
        static let register = "/api/users/register"
        static let currentUser = "/api/users/me"
        static let fastingRecords = "/api/fasting/records"
        static let fastingStatistics = "/api/fasting/statistics"
    }
    
    // MARK: - Headers
    
    struct Headers {
        static let contentType = "application/json"
        static let accept = "application/json"
        static let userAgent = "iFast iOS App"
    }
    
    // MARK: - Validation
    
    struct Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 128
        static let minUsernameLength = 3
        static let maxUsernameLength = 50
        static let maxNameLength = 100
    }
    
    // MARK: - Environment Detection
    
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    static var isDevelopment: Bool {
        return !isProduction
    }
    
    // MARK: - Debug Configuration
    
    #if DEBUG
    static let enableLogging = true
    static let enableNetworkLogging = true
    #else
    static let enableLogging = false
    static let enableNetworkLogging = false
    #endif
}

// MARK: - Environment-specific Configuration

extension APIConfig {
    static var environmentBaseURL: String {
        if isProduction {
            return "https://api.ifast.com" // Replace with your production URL
        } else {
            return baseURL
        }
    }
    
    static var shouldUseStrictSSL: Bool {
        return isProduction
    }
    
    static var enableAnalytics: Bool {
        return isProduction
    }
}
