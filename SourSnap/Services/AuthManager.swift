import AuthenticationServices
import SwiftUI
import SwiftData

@MainActor
@Observable
final class AuthManager: NSObject {
    static let shared = AuthManager()

    // Stored properties tracked by @Observable — synced to UserDefaults for persistence
    var isSignedIn: Bool = UserDefaults.standard.bool(forKey: "isSignedIn") {
        didSet { UserDefaults.standard.set(isSignedIn, forKey: "isSignedIn") }
    }

    var didSkipSignIn: Bool = UserDefaults.standard.bool(forKey: "didSkipSignIn") {
        didSet { UserDefaults.standard.set(didSkipSignIn, forKey: "didSkipSignIn") }
    }

    var userIdentifier: String? = UserDefaults.standard.string(forKey: "userIdentifier") {
        didSet { UserDefaults.standard.set(userIdentifier, forKey: "userIdentifier") }
    }

    var userEmail: String? = UserDefaults.standard.string(forKey: "userEmail") {
        didSet { UserDefaults.standard.set(userEmail, forKey: "userEmail") }
    }

    var userDisplayName: String? = UserDefaults.standard.string(forKey: "userDisplayName") {
        didSet { UserDefaults.standard.set(userDisplayName, forKey: "userDisplayName") }
    }

    var isAuthenticated: Bool {
        isSignedIn || didSkipSignIn
    }

    private var signInContinuation: CheckedContinuation<ASAuthorization, Error>?

    private override init() {
        super.init()
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorization = try await performSignIn(request: request)
        handleAuthorization(authorization)
    }

    private func performSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        userIdentifier = credential.user

        if let email = credential.email {
            userEmail = email
        }

        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                userDisplayName = name
            }
        }

        isSignedIn = true
    }

    func ensureUserProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        if existing.isEmpty {
            let profile = UserProfile(
                displayName: userDisplayName ?? "",
                hasCompletedOnboarding: false,
                subscriptionStatus: "free"
            )
            modelContext.insert(profile)
        }
    }

    // MARK: - Skip Sign In (Free Tier)

    func skipSignIn() {
        didSkipSignIn = true
    }

    // MARK: - Sign Out

    func signOut() {
        isSignedIn = false
        didSkipSignIn = false
        userIdentifier = nil
        userEmail = nil
        userDisplayName = nil
    }

    // MARK: - Check Credential State

    func checkCredentialState() async {
        guard let userIdentifier else { return }

        do {
            let state = try await ASAuthorizationAppleIDProvider()
                .credentialState(forUserID: userIdentifier)
            if state == .revoked || state == .notFound {
                signOut()
            }
        } catch {
            // Credential check failed — keep current state
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        MainActor.assumeIsolated {
            signInContinuation?.resume(returning: authorization)
            signInContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        MainActor.assumeIsolated {
            signInContinuation?.resume(throwing: error)
            signInContinuation = nil
        }
    }
}
