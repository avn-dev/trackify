import SwiftUI

@MainActor
struct RootView: View {
    @State private var auth = AuthState()
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = "system"

    private var preferredScheme: ColorScheme? {
        switch colorSchemeOverride {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil
        }
    }

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                AuthFlow(auth: auth)
            }
        }
        .environment(auth)
        .preferredColorScheme(preferredScheme)
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .task {
            await NotificationScheduler.shared.requestAuthorization()
        }
    }
}

// MARK: - Auth state

@MainActor @Observable
final class AuthState {
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var userName: String = ""
    var userEmail: String = ""

    var userInitials: String {
        let parts = userName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    private let auth = AuthService.shared

    init() {
        Task { @MainActor in
            if let user = await auth.restoreSession() {
                userName = user.name
                userEmail = user.email
                isAuthenticated = true
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let user = try await auth.signIn(email: email, password: password)
        userName = user.name
        userEmail = user.email
        isAuthenticated = true
    }

    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let user = try await auth.signUp(email: email, password: password, name: name)
        userName = user.name
        userEmail = user.email
        isAuthenticated = true
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let user = try await auth.signInWithApple(idToken: idToken, nonce: nonce)
        userName = user.name
        userEmail = user.email
        isAuthenticated = true
    }

    func resetPassword(email: String) async throws {
        try await auth.resetPassword(email: email)
    }

    func signOut() {
        Task {
            try? await auth.signOut()
            isAuthenticated = false
        }
    }
}

// MARK: - Auth navigation

struct AuthFlow: View {
    var auth: AuthState
    @State private var path = NavigationPath()
    @State private var showSplash = true

    var body: some View {
        NavigationStack(path: $path) {
            if showSplash {
                SplashView {
                    withAnimation { showSplash = false }
                }
            } else {
                OnboardingView {
                    path.append(AuthRoute.login)
                }
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .login:    LoginView(auth: auth, path: $path)
                    case .register: RegisterView(auth: auth, path: $path)
                    }
                }
            }
        }
    }
}

enum AuthRoute: Hashable { case login, register }
