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

    var iconFilled: String {
        switch self {
        case .journal: return "book.fill"
        case .snap: return "camera.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }

    var iconOutlined: String {
        switch self {
        case .journal: return "book"
        case .snap: return "camera"
        case .chat: return "bubble.left.and.bubble.right"
        case .profile: return "person"
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
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.appTextPrimary.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: AppTab) -> some View {
        Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: selectedTab == tab ? tab.iconFilled : tab.iconOutlined)
                    .font(.system(size: tab == .snap ? 26 : 22, weight: .semibold))

                Text(tab.label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(selectedTab == tab ? .white : Color.appTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
