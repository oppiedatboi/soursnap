import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @Query private var profiles: [StarterProfile]
    @Query private var userProfiles: [UserProfile]

    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showPaywall = false
    @FocusState private var isFocused: Bool

    private var isProUser: Bool {
        userProfiles.first?.isPro ?? false
    }

    private var todayUserMessageCount: Int {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return messages.filter { $0.role == "user" && $0.createdAt >= startOfDay }.count
    }

    private var hasReachedDailyChatLimit: Bool {
        !isProUser && todayUserMessageCount >= 5
    }

    private let suggestedQuestions = [
        "My starter smells weird",
        "When should I feed?",
        "Is it ready to bake?",
        "How do I make it more active?",
        "Can I keep it in the fridge?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if messages.isEmpty && !isTyping {
                        emptyState
                    } else {
                        messageList
                    }

                    inputBar
                }
            }
            .navigationTitle("Chat with Bub")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                BubMascot(pose: .hero, size: 160)

                VStack(spacing: 8) {
                    Text("Hey! I'm Bub, your sourdough buddy")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Ask me anything about your starter")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }

                VStack(spacing: 10) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        Button {
                            HapticManager.light()
                            sendMessage(question)
                        } label: {
                            HStack {
                                Text(question)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundStyle(Color.appTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(Color.appPrimary)
                            }
                            .padding(14)
                            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.persistentModelID)
                    }

                    if isTyping {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isTyping) { _, newValue in
                if newValue { scrollToBottom(proxy: proxy) }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.3)) {
            if isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.persistentModelID, anchor: .bottom)
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 12) {
            BubMascot(pose: .thinking, size: 36)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 8, height: 8)
                        .offset(y: typingDotOffset(index: i))
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: isTyping
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18))

            Spacer()
        }
    }

    private func typingDotOffset(index: Int) -> CGFloat {
        isTyping ? -4 : 4
    }

    // MARK: - Input Bar

    private var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Bub anything...", text: $inputText, axis: .vertical)
                .font(.system(size: 16, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.appSurface, in: Capsule())
                .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))
                .focused($isFocused)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit { sendCurrentMessage() }

            if hasText {
                Button {
                    sendCurrentMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.appPrimary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasText)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appBackground)
    }

    // MARK: - Actions

    private func sendCurrentMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if hasReachedDailyChatLimit {
            HapticManager.warning()
            showPaywall = true
            return
        }

        inputText = ""
        HapticManager.medium()
        sendMessage(text)
    }

    private func sendMessage(_ text: String) {
        // Save user message
        let userMsg = ChatMessage(role: "user", content: text)
        userMsg.starterProfile = profiles.first
        modelContext.insert(userMsg)

        isTyping = true

        // Build history from recent messages (last 10)
        let recentMessages = messages.suffix(10)
        let history = recentMessages.map { (role: $0.role, content: $0.content) }

        Task {
            do {
                let response = try await OpenAIService.shared.sendChatMessage(text, history: history)
                await MainActor.run {
                    let assistantMsg = ChatMessage(role: "assistant", content: response)
                    assistantMsg.starterProfile = profiles.first
                    modelContext.insert(assistantMsg)
                    isTyping = false
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    let errorMsg = ChatMessage(role: "assistant", content: "Hmm, I'm having trouble thinking right now. Give me a sec and try again! 🤔")
                    errorMsg.starterProfile = profiles.first
                    modelContext.insert(errorMsg)
                    isTyping = false
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: ChatMessage
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isAssistant {
                BubMascot(pose: .thinking, size: 32)
            }

            if message.isUser { Spacer(minLength: 60) }

            Text(message.content)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(message.isUser ? .white : Color.appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isUser ? Color.appPrimary : Color.appSurface,
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay(
                    message.isAssistant ?
                    RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1) : nil
                )

            if message.isAssistant { Spacer(minLength: 60) }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
