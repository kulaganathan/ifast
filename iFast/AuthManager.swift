import Foundation
import AuthAPI
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    private let userAPI: UserAPI
    private let tokenStore: KeychainTokenStore
    
    init() {
        self.tokenStore = KeychainTokenStore()
        let client = APIClient(
            baseURL: URL(string: APIConfig.environmentBaseURL)!,
            tokenStore: tokenStore
        )
        self.authService = AuthService(client: client, tokenStore: tokenStore)
        self.userAPI = UserAPI(client: client)
        
        // Check if user is already authenticated
        Task {
            await checkAuthenticationStatus()
        }
        
        #if DEBUG
        if APIConfig.enableLogging {
            print("AuthManager initialized with base URL: \(APIConfig.environmentBaseURL)")
        }
        #endif
    }
    
    // MARK: - Authentication Methods
    
    func login(username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.login(username: username, password: password)
            await fetchCurrentUser()
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            if let tokenError = error as? TokenStoreError {
                switch tokenError {
                case .keychain(let status):
                    errorMessage = "Login failed: Unable to save authentication tokens (Keychain error: \(status)). Please check your device settings."
                case .encoding:
                    errorMessage = "Login failed: Unable to process authentication tokens. Please try again."
                }
            } else if let apiError = error as? APIError {
                switch apiError {
                case .http(let statusCode):
                    switch statusCode {
                    case 401:
                        errorMessage = "Invalid username or password. Please check your credentials."
                    case 400:
                        errorMessage = "Invalid login data. Please check your input."
                    case 422:
                        errorMessage = "Validation failed. Please check your credentials."
                    default:
                        errorMessage = "Login failed with status code: \(statusCode)"
                    }
                case .decoding(let decodeError):
                    errorMessage = "Login failed: Invalid response from server"
                    #if DEBUG
                    print("Decoding error: \(decodeError)")
                    #endif
                case .network(let networkError):
                    errorMessage = "Login failed: Network error - \(networkError.localizedDescription)"
                case .unauthorized:
                    errorMessage = "Login failed: Unauthorized request"
                case .invalidURL:
                    errorMessage = "Login failed: Invalid server configuration"
                }
            } else {
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
            isLoading = false
            return false
        }
    }
    
    func signup(firstName: String, lastName: String, email: String, username: String, password: String) async -> Bool {
        #if DEBUG
        if APIConfig.enableLogging {
            print("Starting signup process for user: \(username)")
        }
        #endif
        
        // Validate input
        guard password.count >= APIConfig.Validation.minPasswordLength else {
            errorMessage = "Password must be at least \(APIConfig.Validation.minPasswordLength) characters long"
            return false
        }
        
        guard username.count >= APIConfig.Validation.minUsernameLength else {
            errorMessage = "Username must be at least \(APIConfig.Validation.minUsernameLength) characters long"
            return false
        }
        
        // Check keychain access before proceeding
        guard checkKeychainAccess() else {
            errorMessage = "Unable to access secure storage. Please check your device settings and try again."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UserRegistrationRequest(
                username: username,
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            #if DEBUG
            if APIConfig.enableLogging {
                print("Sending registration request to API...")
            }
            #endif
            
            let user = try await userAPI.register(request)
            currentUser = user
            
            #if DEBUG
            if APIConfig.enableLogging {
                print("Registration successful, user ID: \(user.id ?? -1)")
                print("Attempting automatic login...")
            }
            #endif
            
            // After successful registration, try to automatically log in
            // If login fails due to keychain issues, we'll still consider signup successful
            // but show a message that the user needs to log in manually
            do {
                let loginSuccess = await login(username: username, password: password)
                if loginSuccess {
                    #if DEBUG
                    if APIConfig.enableLogging {
                        print("Automatic login successful")
                    }
                    #endif
                    isLoading = false
                    return true
                } else {
                    // Login failed but signup was successful
                    #if DEBUG
                    if APIConfig.enableLogging {
                        print("Automatic login failed, but signup was successful")
                    }
                    #endif
                    isLoading = false
                    errorMessage = "Account created successfully! Please log in manually."
                    return false
                }
            } catch {
                // Handle keychain or other login errors gracefully
                #if DEBUG
                if APIConfig.enableLogging {
                    print("Login error during signup: \(error)")
                                    if let tokenError = error as? TokenStoreError {
                    print("Token store error: \(tokenError)")
                }
                }
                #endif
                
                isLoading = false
                if let tokenError = error as? TokenStoreError {
                    switch tokenError {
                    case .keychain(let status):
                        errorMessage = "Account created successfully! Please log in manually. (Keychain access issue: \(status))"
                    case .encoding:
                        errorMessage = "Account created successfully! Please log in manually. (Token encoding issue)"
                    }
                } else {
                    errorMessage = "Account created successfully! Please log in manually. (Login error: \(error.localizedDescription))"
                }
                return false
            }
        } catch {
            #if DEBUG
            if APIConfig.enableLogging {
                print("Signup API error: \(error)")
                if let apiError = error as? APIError {
                    print("API Error type: \(apiError)")
                    
                    // If it's a decoding error, try to get more details about the date format
                    if case .decoding(let decodeError) = apiError {
                        print("Decoding error details: \(decodeError)")
                        
                        // Try to extract the raw response to see the date format
                        if let decodingError = decodeError as? DecodingError {
                            switch decodingError {
                            case .dataCorrupted(let context):
                                print("Data corrupted context: \(context)")
                                if context.debugDescription.contains("Expected date string to be ISO8601-formatted") {
                                    print("⚠️ Date format issue detected. The API is returning dates in a non-ISO8601 format.")
                                    print("💡 You can use APIClient.testDateFormats() to test different date formats.")
                                }
                            default:
                                print("Other decoding error: \(decodingError)")
                            }
                        }
                    }
                }
            }
            #endif
            
            // Handle signup API errors
            if let apiError = error as? APIError {
                switch apiError {
                case .http(let statusCode):
                    switch statusCode {
                    case 409:
                        errorMessage = "Username or email already exists. Please choose different credentials."
                    case 400:
                        errorMessage = "Invalid signup data. Please check your information."
                    case 422:
                        errorMessage = "Validation failed. Please check your input."
                    default:
                        errorMessage = "Signup failed with status code: \(statusCode)"
                    }
                case .decoding(let decodeError):
                    errorMessage = "Signup failed: Invalid response from server"
                    #if DEBUG
                    print("Decoding error: \(decodeError)")
                    #endif
                case .network(let networkError):
                    errorMessage = "Signup failed: Network error - \(networkError.localizedDescription)"
                case .unauthorized:
                    errorMessage = "Signup failed: Unauthorized request"
                case .invalidURL:
                    errorMessage = "Signup failed: Invalid server configuration"
                }
            } else {
                errorMessage = "Signup failed: \(error.localizedDescription)"
            }
            isLoading = false
            return false
        }
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
        } catch {
            // Even if logout fails, clear local state
            #if DEBUG
            if APIConfig.enableLogging {
                print("Logout error: \(error)")
            }
            #endif
        }
        
        // Clear local state
        isAuthenticated = false
        currentUser = nil
        isLoading = false
    }
    
    func fetchCurrentUser() async {
        do {
            currentUser = try await userAPI.getCurrentUser()
        } catch {
            #if DEBUG
            if APIConfig.enableLogging {
                print("Failed to fetch current user: \(error)")
            }
            #endif
            // If we can't fetch user, assume not authenticated
            isAuthenticated = false
        }
    }
    
    private func checkAuthenticationStatus() async {
        do {
            if let _ = try tokenStore.load() {
                await fetchCurrentUser()
                isAuthenticated = currentUser != nil
            } else {
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
    }
    
    // MARK: - Token Management
    
    func refreshTokenIfNeeded() async {
        do {
            try await authService.refreshAccessTokenIfPossible()
        } catch {
            #if DEBUG
            if APIConfig.enableLogging {
                print("Token refresh failed: \(error)")
            }
            #endif
            // If refresh fails, user needs to log in again
            isAuthenticated = false
        }
    }
    
    // MARK: - Keychain Access Check
    
    func checkKeychainAccess() -> Bool {
        #if DEBUG
        if APIConfig.enableLogging {
            print("Checking keychain access...")
        }
        #endif
        
        do {
            // Try to save a test token to verify keychain access
            let testToken = TokenPair(accessToken: "test", refreshToken: "test")
            try tokenStore.save(testToken)
            
            #if DEBUG
            if APIConfig.enableLogging {
                print("Test token saved successfully")
            }
            #endif
            
            try tokenStore.delete()
            
            #if DEBUG
            if APIConfig.enableLogging {
                print("Test token deleted successfully")
            }
            #endif
            
            return true
        } catch {
            #if DEBUG
            if APIConfig.enableLogging {
                print("Keychain access check failed: \(error)")
                if let tokenError = error as? TokenStoreError {
                    print("Token store error type: \(tokenError)")
                }
            }
            #endif
            return false
        }
    }
    
    func getKeychainTroubleshootingSteps() -> [String] {
        return [
            "1. Go to Settings > Privacy & Security > Keychain",
            "2. Make sure iCloud Keychain is enabled",
            "3. Try toggling iCloud Keychain off and on",
            "4. Restart your device",
            "5. Check if you have any restrictions enabled",
            "6. Ensure you're signed into iCloud"
        ]
    }
    
    // MARK: - Debugging Methods
    
    #if DEBUG
    /// Test different date formats to help identify the correct format
    func testDateFormat(_ dateString: String) {
        print("🔍 Testing date format for: '\(dateString)'")
        APIClient.testDateFormats(dateString)
    }
    #endif
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - User Validation
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= APIConfig.Validation.minPasswordLength &&
               password.count <= APIConfig.Validation.maxPasswordLength
    }
    
    func validateUsername(_ username: String) -> Bool {
        return username.count >= APIConfig.Validation.minUsernameLength &&
               username.count <= APIConfig.Validation.maxUsernameLength
    }
}
