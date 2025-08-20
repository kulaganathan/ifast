import Foundation
import AuthAPI

class FastingAPIService: ObservableObject {
    private let client: APIClient
    private let tokenStore: KeychainTokenStore
    
    init() {
        self.tokenStore = KeychainTokenStore()
        self.client = APIClient(
            baseURL: URL(string: APIConfig.environmentBaseURL)!,
            tokenStore: tokenStore
        )
        
        #if DEBUG
        if APIConfig.enableLogging {
            print("FastingAPIService initialized with base URL: \(APIConfig.environmentBaseURL)")
        }
        #endif
    }
    
    // Example: Fetch user's fasting data from protected endpoint
    func fetchUserFastingData() async throws -> [FastRecord] {
        // This would be a protected endpoint that requires authentication
        // The APIClient automatically handles token refresh
        let response: [FastRecord] = try await client.request(
            APIConfig.Endpoints.fastingRecords,
            method: "GET",
            requiresAuth: true,
            as: [FastRecord].self
        )
        return response
    }
    
    // Example: Create a new fasting record
    func createFastingRecord(_ record: FastRecord) async throws -> FastRecord {
        let response: FastRecord = try await client.request(
            APIConfig.Endpoints.fastingRecords,
            method: "POST",
            body: record,
            requiresAuth: true,
            as: FastRecord.self
        )
        return response
    }
    
    // Example: Update a fasting record
    func updateFastingRecord(_ record: FastRecord) async throws -> FastRecord {
        let response: FastRecord = try await client.request(
            "\(APIConfig.Endpoints.fastingRecords)/\(record.id.uuidString)",
            method: "PUT",
            body: record,
            requiresAuth: true,
            as: FastRecord.self
        )
        return response
    }
    
    // Example: Delete a fasting record
    func deleteFastingRecord(id: UUID) async throws -> String {
        let response: String = try await client.request(
            "\(APIConfig.Endpoints.fastingRecords)/\(id.uuidString)",
            method: "DELETE",
            requiresAuth: true,
            as: String.self
        )
        return response
    }
    
    // Example: Get fasting statistics
    func getFastingStatistics() async throws -> FastingStatistics {
        let response: FastingStatistics = try await client.request(
            APIConfig.Endpoints.fastingStatistics,
            method: "GET",
            requiresAuth: true,
            as: FastingStatistics.self
        )
        return response
    }
    
    // Example: Get fasting records for a specific date range
    func getFastingRecords(from startDate: Date, to endDate: Date) async throws -> [FastRecord] {
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: startDate)
        let endString = dateFormatter.string(from: endDate)
        
        let query = [
            URLQueryItem(name: "startDate", value: startString),
            URLQueryItem(name: "endDate", value: endString)
        ]
        
        let response: [FastRecord] = try await client.request(
            APIConfig.Endpoints.fastingRecords,
            method: "GET",
            query: query,
            requiresAuth: true,
            as: [FastRecord].self
        )
        return response
    }
    
    // Example: Get fasting records by type
    func getFastingRecords(byType type: FastType) async throws -> [FastRecord] {
        let query = [URLQueryItem(name: "type", value: type.displayName)]
        
        let response: [FastRecord] = try await client.request(
            APIConfig.Endpoints.fastingRecords,
            method: "GET",
            query: query,
            requiresAuth: true,
            as: [FastRecord].self
        )
        return response
    }
}

// Example data models for the API
struct FastingStatistics: Codable {
    let totalFastingHours: Double
    let averageFastingDuration: Double
    let longestFast: Double
    let currentStreak: Int
    let totalFasts: Int
}

// Note: FastRecord and FastType already conform to Codable in their original files
// No need to add extensions here since they're already properly configured