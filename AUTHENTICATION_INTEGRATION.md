# Authentication Integration Guide for iFast

This document explains how to use the integrated authentication system in the iFast app.

## Overview

The authentication system integrates the `AuthAPI` Swift SDK to provide secure user authentication with automatic token management, refresh, and secure storage.

## Components

### 1. AuthManager

The main wrapper class that provides a clean interface for authentication operations.

**Key Features:**

- Automatic token refresh
- Secure token storage using Keychain
- User state management
- Error handling

**Methods:**

- `login(username:password:)` - Authenticate user
- `signup(firstName:lastName:email:username:password:)` - Create new account
- `logout()` - Sign out user
- `fetchCurrentUser()` - Get current user profile
- `refreshTokenIfNeeded()` - Manually refresh tokens

### 2. Authentication UI

- **LoginView** - Email/password login
- **SignupView** - User registration form
- **ProfileView** - User profile with logout option

### 3. FastingAPIService

Example service showing how to make authenticated API calls.

## Usage Examples

### 1. Logging In a User

```swift
@StateObject var authManager = AuthManager()

// In your view
Button("Sign In") {
    Task {
        let success = await authManager.login(
            username: "user@example.com",
            password: "password123"
        )
        if success {
            // User is now authenticated
            // App will automatically navigate to main content
        }
    }
}
```

### 2. Signing Up a New User

```swift
Button("Create Account") {
    Task {
        let success = await authManager.signup(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            username: "johndoe",
            password: "password123"
        )
        if success {
            // Account created and user is logged in
        }
    }
}
```

### 3. Fetching Protected Fasting Data

```swift
@StateObject var fastingService = FastingAPIService()

// Fetch user's fasting records
Button("Load Fasting Data") {
    Task {
        do {
            let records = try await fastingService.fetchUserFastingData()
            // Handle the fasting records
        } catch {
            // Handle error
        }
    }
}
```

### 4. Creating a New Fasting Record

```swift
let newRecord = FastRecord(
    id: UUID().uuidString,
    startTime: Date(),
    endTime: nil,
    duration: 0,
    type: FastType(name: "16:8", targetHours: 16, description: "16 hour fast"),
    notes: "Starting my fast"
)

Task {
    do {
        let savedRecord = try await fastingService.createFastingRecord(newRecord)
        // Record created successfully
    } catch {
        // Handle error
    }
}
```

### 5. Handling Token Refresh

The system automatically handles token refresh, but you can manually trigger it if needed:

```swift
// Manual token refresh
Task {
    await authManager.refreshTokenIfNeeded()
}
```

### 6. Logging Out

```swift
Button("Sign Out") {
    Task {
        await authManager.logout()
        // User will be automatically redirected to login screen
    }
}
```

## App Flow

1. **App Launch**: Checks for existing valid tokens
2. **If Authenticated**: Shows main fasting dashboard
3. **If Not Authenticated**: Shows login screen
4. **After Login/Signup**: Automatically navigates to dashboard
5. **Logout**: Clears tokens and returns to login

## Error Handling

The system provides comprehensive error handling:

```swift
// Check for errors
if let errorMessage = authManager.errorMessage {
    Text(errorMessage)
        .foregroundColor(.red)
}

// Clear errors
authManager.clearError()
```

## Security Features

- **Secure Storage**: Tokens stored in iOS Keychain
- **Automatic Refresh**: Tokens refreshed before expiration
- **Token Validation**: Automatic validation on each request
- **Secure Logout**: Complete token cleanup on logout

## Configuration

### Base URL

Update the base URL in `AuthManager.swift`:

```swift
let client = APIClient(
    baseURL: URL(string: "https://your-api-server.com")!,
    tokenStore: tokenStore
)
```

### Custom Headers

Add custom headers in `APIClient.swift`:

```swift
request.setValue("Custom-Header-Value", forHTTPHeaderField: "Custom-Header")
```

## Testing

### Unit Tests

Test authentication flows:

```swift
func testLoginSuccess() async {
    let authManager = AuthManager()
    let success = await authManager.login(username: "test", password: "test")
    XCTAssertTrue(success)
    XCTAssertTrue(authManager.isAuthenticated)
}
```

### UI Tests

Test authentication UI:

```swift
func testLoginFlow() {
    let app = XCUIApplication()
    app.launch()

    // Test login form
    let usernameField = app.textFields["Username"]
    usernameField.tap()
    usernameField.typeText("testuser")

    let passwordField = app.secureTextFields["Password"]
    passwordField.tap()
    passwordField.typeText("testpass")

    app.buttons["Sign In"].tap()

    // Verify navigation to main app
    XCTAssertTrue(app.tabBars["Tab Bar"].exists)
}
```

## Troubleshooting

### Common Issues

1. **Token Expired**: System automatically refreshes, but check network connectivity
2. **Authentication Failed**: Verify credentials and server status
3. **Keychain Access**: Ensure app has proper entitlements for Keychain access

### Debug Mode

Enable debug logging:

```swift
// Add to AuthManager init
#if DEBUG
print("AuthManager initialized with base URL: \(client.baseURL)")
#endif
```

## Best Practices

1. **Always use async/await** for authentication operations
2. **Handle errors gracefully** and show user-friendly messages
3. **Validate input** before sending to server
4. **Use loading states** during authentication operations
5. **Implement proper error recovery** for network issues

## Future Enhancements

- Biometric authentication (Face ID/Touch ID)
- Social login integration
- Multi-factor authentication (MFA)
- Offline authentication support
- Enhanced security features

## Support

For issues or questions about the authentication system:

1. Check the error logs in Xcode console
2. Verify network connectivity
3. Check server status and API endpoints
4. Review token expiration settings
