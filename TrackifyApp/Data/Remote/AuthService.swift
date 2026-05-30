import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Response DTOs

struct AuthTokenResponse: Decodable {
    let token: String
    let user: RemoteUser
}

struct RemoteUser: Decodable {
    let id: Int
    let name: String
    let email: String
}

// MARK: - AuthService

/// Calls Laravel Sanctum endpoints. Tokens are stored in the Keychain.
///
/// Expected Laravel routes (api.php):
///   POST /auth/login        → AuthTokenResponse
///   POST /auth/register     → AuthTokenResponse
///   POST /auth/apple        → AuthTokenResponse
///   POST /auth/logout       → 204
///   GET  /auth/me           → RemoteUser
@MainActor
final class AuthService {

    static let shared = AuthService()
    private let api = APIClient.shared

    // MARK: - Session restore

    /// Returns the stored user if the token is still valid.
    func restoreSession() async -> RemoteUser? {
        guard KeychainService.shared.token != nil else { return nil }
        return try? await api.get("/auth/me")
    }

    // MARK: - Email / password

    func signIn(email: String, password: String) async throws -> RemoteUser {
        struct Body: Encodable { let email: String; let password: String }
        let response: AuthTokenResponse = try await api.post(
            "/auth/login",
            body: Body(email: email, password: password)
        )
        KeychainService.shared.token = response.token
        return response.user
    }

    func signUp(email: String, password: String, name: String) async throws -> RemoteUser {
        struct Body: Encodable { let name: String; let email: String; let password: String }
        let response: AuthTokenResponse = try await api.post(
            "/auth/register",
            body: Body(name: name, email: email, password: password)
        )
        KeychainService.shared.token = response.token
        return response.user
    }

    // MARK: - Sign in with Apple

    /// Send the Apple identity token to Laravel; Laravel verifies with Apple and returns a Sanctum token.
    func signInWithApple(idToken: String, nonce: String) async throws -> RemoteUser {
        struct Body: Encodable { let identityToken: String; let nonce: String }
        let response: AuthTokenResponse = try await api.post(
            "/auth/apple",
            body: Body(identityToken: idToken, nonce: nonce)
        )
        KeychainService.shared.token = response.token
        return response.user
    }

    // MARK: - Password reset

    func resetPassword(email: String) async throws {
        struct Body: Encodable { let email: String }
        struct Empty: Decodable {}
        let _: Empty = try await api.post("/auth/password/reset", body: Body(email: email))
    }

    // MARK: - Sign out

    func signOut() async throws {
        try await api.post("/auth/logout")
        KeychainService.shared.token = nil
    }
}

// MARK: - Apple Sign-In crypto helpers

func randomNonce(length: Int = 32) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return bytes.map { String(format: "%02x", $0) }.joined()
}

func sha256(_ input: String) -> String {
    let hash = SHA256.hash(data: Data(input.utf8))
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

// MARK: - Apple Sign-In delegate (shared by LoginView & RegisterView)

nonisolated(unsafe) var appleSignInDelegateKey: UInt8 = 0

final class AppleSignInDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(credential))
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}
