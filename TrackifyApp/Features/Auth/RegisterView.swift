import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    @Environment(\.theme) private var t
    var auth: AuthState
    @Binding var path: NavigationPath

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var agreedToTerms = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showGoogleAlert = false
    @State private var currentNonce: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { path.removeLast() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Zurück")
                            .font(.custom(Typography.geist, size: 14))
                    }
                    .foregroundStyle(t.textMid)
                }
                .buttonStyle(.plain)

                Text("Erstell dir\ndeinen Account.")
                    .font(.custom(Typography.geist, size: 34).weight(.semibold))
                    .kerning(-1.2)
                    .foregroundStyle(t.text)
                    .padding(.top, 24)
                Text("30 Sekunden. Versprochen.")
                    .font(Typography.body)
                    .foregroundStyle(t.textMuted)
                    .padding(.top, 6)

                VStack(spacing: 10) {
                    AuthField(label: "Name", text: $name, isSecure: false)
                    AuthField(label: "E-Mail", text: $email, isSecure: false)
                    AuthField(label: "Passwort", text: $password, isSecure: true)

                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            withAnimation(.spring(duration: 0.2)) { agreedToTerms.toggle() }
                        } label: {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(agreedToTerms ? t.accent : t.surface2)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(t.accentText)
                                        .opacity(agreedToTerms ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 1)

                        (Text("Ich akzeptiere die ")
                            .foregroundStyle(t.textMid)
                        + Text("AGB").underline().foregroundStyle(t.text)
                        + Text(" & ").foregroundStyle(t.textMid)
                        + Text("Datenschutz").underline().foregroundStyle(t.text)
                        + Text(".").foregroundStyle(t.textMid))
                            .font(.custom(Typography.geist, size: 13))
                    }
                    .padding(.top, 6)
                }
                .padding(.top, 28)

                if let error {
                    Text(error)
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                PrimaryButton(title: "Konto erstellen", systemIcon: "arrow.right", isLoading: isLoading) {
                    Task { await doRegister() }
                }
                .disabled(!agreedToTerms || isLoading)
                .opacity(agreedToTerms ? 1 : 0.5)
                .padding(.top, 18)

                AuthDivider(label: "oder")

                HStack(spacing: 10) {
                    GhostButton(title: "Google", systemIcon: "globe") {
                        showGoogleAlert = true
                    }
                    GhostButton(title: "Apple", systemIcon: "apple.logo") {
                        startAppleSignIn()
                    }
                }
            }
            .padding(.top, 68)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 44)
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Bald verfügbar", isPresented: $showGoogleAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Google Sign-In wird in einer der nächsten Versionen verfügbar sein.")
        }
    }

    private func doRegister() async {
        error = nil
        isLoading = true
        do {
            try await auth.signUp(email: email, password: password, name: name)
        } catch {
            self.error = (error as? APIError)?.errorDescription ?? "Registrierung fehlgeschlagen."
        }
        isLoading = false
    }

    private func startAppleSignIn() {
        let nonce = randomNonce()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { result in
            Task { @MainActor in
                switch result {
                case .success(let credential):
                    guard let tokenData = credential.identityToken,
                          let idToken = String(data: tokenData, encoding: .utf8),
                          let nonce = self.currentNonce else { return }
                    try? await self.auth.signInWithApple(idToken: idToken, nonce: nonce)
                case .failure:
                    break
                }
            }
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
        objc_setAssociatedObject(controller, &appleSignInDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
    }
}

#Preview {
    ThemedRoot {
        NavigationStack {
            RegisterView(auth: AuthState(), path: .constant(NavigationPath()))
        }
    }
}
