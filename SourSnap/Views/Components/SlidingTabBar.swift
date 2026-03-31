import SwiftUI

enum AppTab: Int, CaseIterable {
    case journal = 0
    case snap = 1
    case chat = 2
    case profile = 3

    var label: String {
        switch self {
        case .journal: return "Journal"
        case .snap: return "Snap"
        case .chat: return "Chat"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .journal: return "book.fill"
        case .snap: return "camera.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }
}

struct SlidingTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(Color.appSurface)
        .clipShape(Capsule())
        .shadow(color: Color.appTextPrimary.opacity(0.08), radius: 8, y: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: AppTab) -> some View {
        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: tab == .snap ? 22 : 18, weight: .semibold))

                Text(tab.label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selectedTab == tab ? .white : Color.appTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(Color.appPrimary)
                        .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
