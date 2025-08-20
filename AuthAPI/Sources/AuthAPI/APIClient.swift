import Foundation

public enum APIError: Error {
    case invalidURL
    case http(Int)
    case decoding(Error)
    case network(Error)
    case unauthorized
}

public final class APIClient: @unchecked Sendable {
    public let baseURL: URL
    private let urlSession: URLSession
    private let tokenStore: TokenStore
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    public init(baseURL: URL = URL(string: "http://localhost:8080")!,
                tokenStore: TokenStore = KeychainTokenStore(),
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.urlSession = session
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder = JSONEncoder()
        
        // Use a flexible date decoding strategy that can handle multiple formats
        self.jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            #if DEBUG
            print("Attempting to decode date string: '\(dateString)'")
            #endif
            
            // Try multiple date formats
            let formatters: [DateFormatter] = [
                // ISO8601 format with milliseconds
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    return formatter
                }(),
                // ISO8601 without milliseconds
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    return formatter
                }(),
                // ISO8601 date only
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    return formatter
                }(),
                // Common API date format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return formatter
                }(),
                // Date only format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    return formatter
                }(),
                // RFC 3339 format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    return formatter
                }(),
                // RFC 3339 with timezone offset
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    return formatter
                }(),
                // MySQL datetime format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return formatter
                }(),
                // US date format
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                    return formatter
                }()
            ]
            
            // Try each formatter
            for (index, formatter) in formatters.enumerated() {
                if let date = formatter.date(from: dateString) {
                    #if DEBUG
                    print("Date decoded successfully using formatter \(index): \(date)")
                    #endif
                    return date
                }
            }
            
            // If all formatters fail, try parsing as Unix timestamp
            if let timestamp = Double(dateString) {
                let date = Date(timeIntervalSince1970: timestamp)
                #if DEBUG
                print("Date decoded successfully as Unix timestamp: \(date)")
                #endif
                return date
            }
            
            #if DEBUG
            print("Failed to decode date string: '\(dateString)' with any formatter")
            #endif
            
            // If still no success, throw a decoding error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string '\(dateString)' does not match any expected format"
            )
        }
        
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: Core request with automatic token refresh
    public func request<T: Decodable>(_ path: String,
                                      method: String = "GET",
                                      query: [URLQueryItem]? = nil,
                                      body: Encodable? = nil,
                                      requiresAuth: Bool = true,
                                      as type: T.Type) async throws -> T {
        do {
            return try await perform(path, method: method, query: query, body: body, requiresAuth: requiresAuth, as: T.self)
        } catch APIError.unauthorized {
            // Attempt refresh once
            try await AuthService(client: self, tokenStore: tokenStore).refreshAccessTokenIfPossible()
            return try await perform(path, method: method, query: query, body: body, requiresAuth: requiresAuth, as: T.self)
        }
    }
    
    private func perform<T: Decodable>(_ path: String,
                                       method: String,
                                       query: [URLQueryItem]?,
                                       body: Encodable?,
                                       requiresAuth: Bool,
                                       as type: T.Type) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.queryItems = query
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if requiresAuth, let tokens = try tokenStore.load() {
            request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.network(URLError(.badServerResponse)) }
            switch http.statusCode {
            case 200..<300:
                if T.self == String.self, let str = String(data: data, encoding: .utf8) as? T { return str }
                do { 
                    return try jsonDecoder.decode(T.self, from: data) 
                } catch { 
                    #if DEBUG
                    // Log the raw response for debugging date format issues
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("API Response (failed to decode): \(responseString)")
                    }
                    #endif
                    throw APIError.decoding(error) 
                }
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.http(http.statusCode)
            }
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.network(error)
        }
    }
    
    // MARK: - Utility Methods
    
    #if DEBUG
    /// Utility method to help identify date formats during development
    public static func testDateFormats(_ dateString: String) {
        print("Testing date string: '\(dateString)'")
        
        let formatters: [(String, DateFormatter)] = [
            ("ISO8601 with milliseconds", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                return formatter
            }()),
            ("ISO8601 without milliseconds", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter
            }()),
            ("ISO8601 date only", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()),
            ("Common API format", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }()),
            ("Date only", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()),
            ("RFC 3339 UTC", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }()),
            ("RFC 3339 with offset", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter
            }()),
            ("MySQL datetime", {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }()),
            ("US format", {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                return formatter
            }())
        ]
        
        for (name, formatter) in formatters {
            if let date = formatter.date(from: dateString) {
                print("✅ \(name): \(date)")
            } else {
                print("❌ \(name): failed")
            }
        }
        
        // Try Unix timestamp
        if let timestamp = Double(dateString) {
            let date = Date(timeIntervalSince1970: timestamp)
            print("✅ Unix timestamp: \(date)")
        } else {
            print("❌ Unix timestamp: failed")
        }
    }
    #endif
}

// Helper to encode unknown Encodable
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self._encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}


