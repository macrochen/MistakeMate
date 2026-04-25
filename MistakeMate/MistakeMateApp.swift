import SwiftData
import SwiftUI

@main
struct MistakeMateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Subject.self,
            Mistake.self,
            PracticeSet.self,
            PracticeItem.self,
            AppSettings.self,
            ChatSession.self,
            ChatMessage.self,
            PromptTemplate.self
        ]) { result in
            if case .success(let container) = result {
                DataSeeder.seedIfNeeded(context: container.mainContext)
            }
        }
    }
}
