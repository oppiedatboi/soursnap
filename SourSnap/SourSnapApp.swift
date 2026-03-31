import SwiftUI
import SwiftData

@main
struct SourSnapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            StarterProfile.self,
            JournalEntry.self,
            ChatMessage.self,
            FeedingLog.self,
            UserProfile.self
        ])
    }
}
