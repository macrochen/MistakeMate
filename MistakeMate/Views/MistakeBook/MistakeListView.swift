import SwiftData
import SwiftUI

struct MistakeListView: View {
    @Query(sort: \Mistake.createdAt, order: .reverse) private var mistakes: [Mistake]

    var body: some View {
        List {
            if mistakes.isEmpty {
                ContentUnavailableView(
                    "还没有错题",
                    systemImage: "text.book.closed",
                    description: Text("之后可以在这里拍照录入、筛选和复习错题。")
                )
            } else {
                Section("全部错题") {
                    ForEach(mistakes) { mistake in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if let subject = mistake.subject {
                                    Label(subject.name, systemImage: "circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(subject.color)
                                }

                                Text(mistake.mistakeType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }

                            Text(mistake.content)
                                .font(.body)
                                .lineLimit(2)

                            Text(mistake.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("错题本")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Label("添加", systemImage: "plus")
                }
            }
        }
    }
}
