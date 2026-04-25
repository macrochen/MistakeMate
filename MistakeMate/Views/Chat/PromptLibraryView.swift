import SwiftData
import SwiftUI

struct PromptLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PromptTemplate.lastUsedAt, order: .reverse) private var customPrompts: [PromptTemplate]

    let onSelect: (String) -> Void

    @State private var showEditor = false
    @State private var editingPrompt: PromptTemplate?

    private let defaultPrompts: [(String, String)] = [
        ("解题助手", "请帮我分析这道题，指出解题思路和易错点。"),
        ("背诵复习", "请根据这个知识点出几道背诵检测题。"),
        ("提分训练", "针对这个薄弱点，请给我一些专项练习建议。"),
        ("知识讲解", "请用通俗易懂的方式讲解这个概念。"),
        ("错题分析", "请分析我为什么会在这类题目上出错，给我改进建议。"),
    ]

    var body: some View {
        NavigationStack {
            List {
                if !customPrompts.isEmpty {
                    Section("我的定制") {
                        ForEach(customPrompts) { prompt in
                            promptRow(prompt: prompt)
                        }
                    }
                }

                Section("默认提示词") {
                    ForEach(defaultPrompts, id: \.0) { title, content in
                        Button {
                            onSelect(content)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("提示词库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingPrompt = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showEditor) {
                PromptEditorView(
                    prompt: editingPrompt,
                    onSave: { title, content in
                        if let existing = editingPrompt {
                            existing.title = title
                            existing.content = content
                            existing.updatedAt = Date()
                        } else {
                            let new = PromptTemplate(title: title, content: content)
                            modelContext.insert(new)
                        }
                        try? modelContext.save()
                    }
                )
            }
        }
    }

    private func promptRow(prompt: PromptTemplate) -> some View {
        Button {
            prompt.lastUsedAt = Date()
            try? modelContext.save()
            onSelect(prompt.content)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(prompt.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(prompt)
                try? modelContext.save()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                editingPrompt = prompt
                showEditor = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
        }
    }
}

struct PromptEditorView: View {
    let prompt: PromptTemplate?
    let onSave: (String, String) -> Void

    @State private var title: String
    @State private var content: String
    @Environment(\.dismiss) private var dismiss

    init(prompt: PromptTemplate?, onSave: @escaping (String, String) -> Void) {
        self.prompt = prompt
        self.onSave = onSave
        _title = State(initialValue: prompt?.title ?? "")
        _content = State(initialValue: prompt?.content ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("提示词名称", text: $title)
                }
                Section("内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(prompt == nil ? "新建提示词" : "编辑提示词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(title, content)
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}
