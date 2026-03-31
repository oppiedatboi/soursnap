import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab: AppTab = .journal
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        if !hasSeenOnboarding {
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
                .opacity(selectedTab == .journal ? 1 : 0)
                .offset(x: tabOffset(for: .journal))

            SnapView()
                .opacity(selectedTab == .snap ? 1 : 0)
                .offset(x: tabOffset(for: .snap))

            ChatView()
                .opacity(selectedTab == .chat ? 1 : 0)
                .offset(x: tabOffset(for: .chat))

            ProfileView()
                .opacity(selectedTab == .profile ? 1 : 0)
                .offset(x: tabOffset(for: .profile))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
    }

    private func tabOffset(for tab: AppTab) -> CGFloat {
        let diff = CGFloat(tab.rawValue - selectedTab.rawValue)
        return diff * UIScreen.main.bounds.width + (selectedTab == tab ? dragOffset * 0.3 : 0)
    }
}
