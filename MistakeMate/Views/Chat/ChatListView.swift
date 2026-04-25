import SwiftData
import SwiftUI

struct ChatListView: View {
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "还没有对话",
                    systemImage: "message",
                    description: Text("之后可以在这里和 AI 讨论错题、上传图片、保存历史。")
                )
            } else {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title)
                            .font(.headline)
                        Text(session.updatedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("AI助手")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Label("新建对话", systemImage: "square.and.pencil")
                }
            }
        }
    }
}
