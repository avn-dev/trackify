import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.theme) private var t
    var auth: AuthState
    @Binding var path: NavigationPath

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var currentNonce: String?
    @State private var showForgotAlert = false
    @State private var showGoogleAlert = false
    @State private var forgotEmailSent = false
    @State private var forgotEmail = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TrackifyLogomark(size: 42).padding(.bottom, 32)

                Text("Willkommen\nzurück.")
                    .font(.custom(Typography.geist, size: 34).weight(.semibold))
                    .kerning(-1.2)
                    .foregroundStyle(t.text)
                    .lineSpacing(2)
                Text("Schön, dass du wieder da bist.")
                    .font(Typography.body)
                    .foregroundStyle(t.textMuted)
                    .padding(.top, 6)

                VStack(spacing: 12) {
                    AuthField(label: "E-Mail", text: $email, isSecure: false)
                    AuthField(label: "Passwort", text: $password, isSecure: true) {
                        Button("vergessen?") {
                            forgotEmail = email
                            showForgotAlert = true
                        }
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.textMid)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 32)

                if let error {
                    Text(error)
                        .font(Typography.bodySmall)
                        .foregroundStyle(t.danger)
                        .padding(.top, 8)
                }

                PrimaryButton(title: "Login", systemIcon: "arrow.right", isLoading: isLoading) {
                    Task { await doLogin() }
                }
                .padding(.top, 20)

                AuthDivider(label: "oder weiter mit")

                VStack(spacing: 10) {
                    GhostButton(title: "Mit Google fortfahren", systemIcon: "globe") {
                        showGoogleAlert = true
                    }
                    GhostButton(title: "Mit Apple fortfahren", systemIcon: "apple.logo") {
                        startAppleSignIn()
                    }
                }

                Spacer(minLength: 32)

                HStack {
                    Spacer()
                    Text("Noch keinen Account? ")
                        .foregroundStyle(t.textMid)
                    + Text("Registrieren")
                        .foregroundStyle(t.text)
                }
                .font(.custom(Typography.geist, size: 14))
                .onTapGesture { path.append(AuthRoute.register) }
            }
            .padding(.top, 68)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 44)
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Passwort zurücksetzen", isPresented: $showForgotAlert) {
            TextField("E-Mail-Adresse", text: $forgotEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Senden") { Task { await sendReset() } }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Wir senden dir einen Link zum Zurücksetzen deines Passworts.")
        }
        .alert("E-Mail gesendet", isPresented: $forgotEmailSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Falls ein Konto mit dieser Adresse existiert, erhältst du in Kürze einen Link.")
        }
        .alert("Bald verfügbar", isPresented: $showGoogleAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Google Sign-In wird in einer der nächsten Versionen verfügbar sein.")
        }
    }

    private func sendReset() async {
        guard !forgotEmail.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        try? await auth.resetPassword(email: forgotEmail)
        forgotEmailSent = true
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
                          let nonce = currentNonce else {
                        self.error = "Apple Sign-In fehlgeschlagen."
                        return
                    }
                    do {
                        try await auth.signInWithApple(idToken: idToken, nonce: nonce)
                    } catch {
                        self.error = "Apple Sign-In fehlgeschlagen."
                    }
                case .failure:
                    break
                }
            }
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
        // Retain delegate for the duration of the flow
        objc_setAssociatedObject(controller, &appleSignInDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
    }

    private func doLogin() async {
        isLoading = true
        error = nil
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            self.error = "Login fehlgeschlagen. Prüfe E-Mail und Passwort."
        }
        isLoading = false
    }
}

// MARK: - Shared auth form components

struct AuthField<Trailing: View>: View {
    @Environment(\.theme) private var t
    var label: String
    @Binding var text: String
    var isSecure: Bool
    @ViewBuilder var trailing: () -> Trailing

    init(label: String, text: Binding<String>, isSecure: Bool, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.label = label
        self._text = text
        self.isSecure = isSecure
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(Typography.eyebrow)
                    .kerning(0.5)
                    .foregroundStyle(t.textMuted)
                if isSecure {
                    SecureField("", text: $text)
                        .font(.custom(Typography.geist, size: 16))
                        .foregroundStyle(t.text)
                } else {
                    TextField("", text: $text)
                        .font(.custom(Typography.geist, size: 16))
                        .foregroundStyle(t.text)
                        .keyboardType(label == "E-Mail" ? .emailAddress : .default)
                        .autocapitalization(.none)
                }
            }
            trailing()
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).fill(t.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).stroke(t.border, lineWidth: 1)
        )
    }
}

extension AuthField where Trailing == EmptyView {
    init(label: String, text: Binding<String>, isSecure: Bool) {
        self.init(label: label, text: text, isSecure: isSecure) { EmptyView() }
    }
}

struct AuthDivider: View {
    @Environment(\.theme) private var t
    var label: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(t.border).frame(height: 1)
            Text(label.uppercased())
                .font(Typography.eyebrow).kerning(1)
                .foregroundStyle(t.textMuted)
            Rectangle().fill(t.border).frame(height: 1)
        }
        .padding(.vertical, 22)
    }
}

#Preview {
    ThemedRoot {
        NavigationStack {
            LoginView(auth: AuthState(), path: .constant(NavigationPath()))
        }
    }
}
