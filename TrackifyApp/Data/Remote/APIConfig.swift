import Foundation

/// Replace baseURL with your Laravel server address.
/// Example production:  "https://api.trackify.app"
/// Example local dev:   "http://localhost:8000"
enum APIConfig {
    // Cleartext HTTP is only ever used for local development. Gating on DEBUG (not
    // targetEnvironment(simulator)) ensures a release/TestFlight build can never post
    // credentials over plaintext, even when run on a simulator.
#if DEBUG && targetEnvironment(simulator)
    static let baseURL = URL(string: "http://localhost:8002")!
#else
    static let baseURL = URL(string: "https://trackify-api.vision2co.de")!
#endif
}
