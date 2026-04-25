import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MistakeListView()
            }
            .tabItem {
                Label("错题本", systemImage: "text.book.closed")
            }
            .tag(0)

            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Label("AI助手", systemImage: "message")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(2)
        }
    }
}
