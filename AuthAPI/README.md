# AuthAPI

A lightweight Swift SDK for the Auth Server API (OpenAPI 3.0), supporting async/await, token-based auth (access + refresh), secure Keychain storage, and automatic token refresh.

## Installation (Swift Package Manager)

1. In Xcode: File > Add Package Dependencies...
2. Enter the repository URL of this package
3. Select `AuthAPI`

## Usage Example

```swift
import AuthAPI

let client = APIClient(baseURL: URL(string: "http://localhost:8080")!)
let auth = AuthService(client: client)
let users = UserAPI(client: client)

// Login (example; replace when login endpoint exists)
try await auth.login(username: "john", password: "secret")

// Calls will automatically attach Bearer token and auto-refresh on 401
let me = try await users.getCurrentUser()
print("Hello, \(me.username ?? "user")")

// Explicit refresh (usually not needed)
try await auth.refreshAccessTokenIfPossible()

// Update profile
let updated = try await users.updateUserProfile(userId: me.id ?? 0, firstName: "John", lastName: "Doe")
print(updated)

// Logout
try await auth.logout()
```

## Organization

- `Models.swift` – Codable models from the API
- `APIClient.swift` – Core HTTP client with auto-refresh
- `KeychainTokenStore.swift` – Secure token persistence
- `AuthService.swift` – Auth flows (login, refresh, logout)
- `UserAPI.swift` – User-related endpoints

## Updating from OpenAPI spec

This SDK is generated/maintained from `api-docs.json`. In Cursor, enable auto-refresh by watching the spec and applying diffs to `Models.swift`, `UserAPI.swift`, and any new endpoints. You can re-run the generator script below.

### Generator script (manual refresh)

```bash
# Tools required: jq
jq '.paths | keys[]' api-docs.json
# Extend this to regenerate models/endpoints as the spec evolves
```
