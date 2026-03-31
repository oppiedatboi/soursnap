import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var appeared = false

    private let authManager = AuthManager.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero section
                VStack(spacing: 20) {
                    KikoMascot(pose: .hero, size: 200)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)

                    VStack(spacing: 8) {
                        Text("Welcome to Kiko Dough")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appTextPrimary)

                        Text("Your sourdough starter journal")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                }

                Spacer()

                // Features preview
                VStack(spacing: 14) {
                    featureRow(icon: "camera.fill", title: "Snap & Analyze", description: "AI-powered starter health checks")
                    featureRow(icon: "bubble.left.and.bubble.right.fill", title: "Chat with Kiko", description: "Your personal sourdough advisor")
                    featureRow(icon: "chart.line.uptrend.xyaxis", title: "Track Progress", description: "Watch your starter grow over time")
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                // Sign in buttons
                VStack(spacing: 14) {
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { _ in })
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .cornerRadius(26)
                    .overlay {
                        // Custom tap handler over the Apple button
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleSignIn()
                            }
                    }

                    Button {
                        HapticManager.light()
                        authManager.skipSignIn()
                        authManager.ensureUserProfile(modelContext: modelContext)
                    } label: {
                        Text("Continue without account")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }

            if isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                SwiftUI.ProgressView()
                    .tint(Color.appPrimary)
                    .scaleEffect(1.5)
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 36, height: 36)
                .background(Color.appPrimary.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                Text(description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
    }

    private func handleSignIn() {
        guard !isLoading else { return }
        isLoading = true
        HapticManager.medium()

        Task {
            do {
                try await authManager.signInWithApple()
                authManager.ensureUserProfile(modelContext: modelContext)
                HapticManager.success()
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // User canceled — do nothing
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
            isLoading = false
        }
    }
}
