import SwiftData
import SwiftUI

struct ChatListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "还没有对话",
                        systemImage: "message",
                        description: Text("点击右上角按钮开始和 AI 讨论。")
                    )
                } else {
                    ForEach(sessions) { session in
                        NavigationLink(value: session) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.headline)
                                Text(session.updatedAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(session)
                                try? modelContext.save()
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI助手")
            .navigationDestination(for: ChatSession.self) { session in
                ChatDetailView(session: session)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let session = ChatSession()
                        modelContext.insert(session)
                        try? modelContext.save()
                        navigationPath.append(session)
                    } label: {
                        Label("新建对话", systemImage: "square.and.pencil")
                    }
                }
            }
        }
    }
}
