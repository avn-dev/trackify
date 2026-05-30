import Foundation

// MARK: - APIClient

/// Thin URLSession wrapper. Attaches the Sanctum bearer token from Keychain on every request.
final class APIClient: @unchecked Sendable {

    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Requests

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "GET", path: path, body: Optional<EmptyBody>.none)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "POST", path: path, body: body)
    }

    func post(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "POST", path: path, body: Optional<EmptyBody>.none)
    }

    // MARK: - Core

    private func request<B: Encodable, T: Decodable>(
        method: String,
        path: String,
        body: B?
    ) async throws -> T {
        var request = URLRequest(url: APIConfig.baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainService.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 422:
            let errors = (try? decoder.decode(ValidationError.self, from: data))?.message ?? "Validierungsfehler."
            throw APIError.validation(errors)
        default:
            throw APIError.http(http.statusCode)
        }
    }
}

// MARK: - Empty helpers

private struct EmptyBody: Encodable {}
struct EmptyResponse: Decodable {}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case validation(String)
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:     "Ungültige Server-Antwort."
        case .unauthorized:        "Sitzung abgelaufen. Bitte erneut anmelden."
        case .validation(let msg): msg
        case .http(let code):      "Server-Fehler (\(code))."
        }
    }
}

private struct ValidationError: Decodable {
    let message: String
}
