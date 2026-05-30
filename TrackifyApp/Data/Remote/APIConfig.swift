import Foundation

/// Replace baseURL with your Laravel server address.
/// Example production:  "https://api.trackify.app"
/// Example local dev:   "http://localhost:8000"
enum APIConfig {
    static let baseURL = URL(string: "http://localhost:8002")!
}
