import SwiftUI

extension Notification.Name {
    static let switchToSnapTab = Notification.Name("switchToSnapTab")
}

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab: AppTab = .journal
    @State private var dragOffset: CGFloat = 0

    private let authManager = AuthManager.shared

    var body: some View {
        if !authManager.isAuthenticated {
            SignInView()
        } else if !hasSeenOnboarding {
            OnboardingView()
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            // Tab content with slide transitions
            TabContainerView(selectedTab: $selectedTab, dragOffset: $dragOffset)

            // Custom tab bar
            SlidingTabBar(selectedTab: $selectedTab)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSnapTab)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = .snap
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold, selectedTab.rawValue < AppTab.allCases.count - 1 {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = AppTab(rawValue: selectedTab.rawValue + 1)!
                        }
                    } else if value.translation.width > threshold, selectedTab.rawValue > 0 {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = AppTab(rawValue: selectedTab.rawValue - 1)!
                        }
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
    }
}

struct TabContainerView: View {
    @Binding var selectedTab: AppTab
    @Binding var dragOffset: CGFloat

    var body: some View {
        ZStack {
            JournalView()
                .modifier(TabTransition(tab: .journal, selectedTab: selectedTab, dragOffset: dragOffset))

            SnapView(selectedTab: $selectedTab)
                .modifier(TabTransition(tab: .snap, selectedTab: selectedTab, dragOffset: dragOffset))

            ChatView()
                .modifier(TabTransition(tab: .chat, selectedTab: selectedTab, dragOffset: dragOffset))

            ProfileView()
                .modifier(TabTransition(tab: .profile, selectedTab: selectedTab, dragOffset: dragOffset))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedTab)
    }
}

private struct TabTransition: ViewModifier {
    let tab: AppTab
    let selectedTab: AppTab
    let dragOffset: CGFloat

    private var diff: CGFloat {
        CGFloat(tab.rawValue - selectedTab.rawValue)
    }

    private var isSelected: Bool { tab == selectedTab }

    func body(content: Content) -> some View {
        content
            .offset(x: diff * UIScreen.main.bounds.width + (isSelected ? dragOffset * 0.3 : 0))
            .opacity(isSelected ? 1 : max(0, 1 - abs(diff) * 0.5))
            .scaleEffect(isSelected ? 1 : 0.92)
            .allowsHitTesting(isSelected)
    }
}
