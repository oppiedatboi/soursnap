import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var mascotAppeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    onboardingPage(
                        pose: .hero,
                        title: "Meet Bub!",
                        subtitle: "Your sourdough companion",
                        description: "Bub's seen a thousand starters and loves every one. Let's grow something amazing together."
                    )
                    .tag(0)

                    onboardingPage(
                        pose: .snap,
                        title: "Snap Daily",
                        subtitle: "AI-powered analysis",
                        description: "Take a photo of your starter each day. Bub will analyze the bubbles, rise, and color to track your progress."
                    )
                    .tag(1)

                    onboardingPage(
                        pose: .celebrating,
                        title: "Never Bake Alone",
                        subtitle: "Your personal mentor",
                        description: "Chat with Bub anytime. Journal your journey. Celebrate every milestone together."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator + button
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.appPrimary : Color.appBorder)
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.3 : 1)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    Button {
                        HapticManager.medium()
                        if currentPage < 2 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                hasSeenOnboarding = true
                            }
                            HapticManager.success()
                        }
                    } label: {
                        Text(currentPage < 2 ? "Next" : "Get Started")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary, in: Capsule())
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func onboardingPage(pose: MascotPose, title: String, subtitle: String, description: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            BubMascot(pose: pose, size: 200)
                .scaleEffect(mascotAppeared ? 1 : 0.5)
                .opacity(mascotAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: mascotAppeared)
                .onAppear { mascotAppeared = true }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)

                Text(subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
            }

            Text(description)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
