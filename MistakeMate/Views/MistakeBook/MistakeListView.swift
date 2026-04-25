import SwiftData
import SwiftUI

struct MistakeListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Mistake.createdAt, order: .reverse) private var mistakes: [Mistake]
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    @State private var isInputPresented = false
    @State private var searchText = ""
    @State private var selectedSubject: Subject?
    @State private var selectedType = "全部"

    private var filteredMistakes: [Mistake] {
        mistakes.filter { mistake in
            let subjectMatches = selectedSubject == nil || mistake.subject?.persistentModelID == selectedSubject?.persistentModelID
            let typeMatches = selectedType == "全部" || mistake.mistakeType == selectedType
            let searchMatches = searchText.isEmpty ||
                mistake.content.localizedCaseInsensitiveContains(searchText) ||
                mistake.analysis.localizedCaseInsensitiveContains(searchText) ||
                (mistake.knowledgePoint?.localizedCaseInsensitiveContains(searchText) ?? false)

            return subjectMatches && typeMatches && searchMatches
        }
    }

    var body: some View {
        List {
            Section {
                Picker("科目", selection: $selectedSubject) {
                    Text("全部").tag(Optional<Subject>.none)
                    ForEach(subjects) { subject in
                        Text(subject.name).tag(Optional(subject))
                    }
                }

                Picker("错误类型", selection: $selectedType) {
                    Text("全部").tag("全部")
                    ForEach(Mistake.mistakeTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }

            if filteredMistakes.isEmpty {
                ContentUnavailableView(
                    mistakes.isEmpty ? "还没有错题" : "没有匹配的错题",
                    systemImage: "text.book.closed",
                    description: Text("可以调整筛选条件，或点击右上角添加。")
                )
            } else {
                Section("全部错题") {
                    ForEach(filteredMistakes) { mistake in
                        NavigationLink {
                            MistakeDetailView(mistake: mistake)
                        } label: {
                            MistakeRow(mistake: mistake)
                        }
                    }
                    .onDelete(perform: deleteMistakes)
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索题目、分析、知识点")
        .navigationTitle("错题本")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isInputPresented = true
                } label: {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isInputPresented) {
            MistakeInputView()
        }
    }

    private func deleteMistakes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredMistakes[index])
        }
        try? modelContext.save()
    }
}

private struct MistakeRow: View {
    let mistake: Mistake

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let subject = mistake.subject {
                    Label(subject.name, systemImage: "circle.fill")
                        .foregroundStyle(subject.color)
                }

                Text(mistake.mistakeType)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(mistake.createdAt, style: .date)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Text(mistake.content)
                .font(.body.weight(.semibold))
                .lineLimit(2)

            if let knowledgePoint = mistake.knowledgePoint, !knowledgePoint.isEmpty {
                Text(knowledgePoint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
