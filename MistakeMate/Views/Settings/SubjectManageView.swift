import SwiftData
import SwiftUI

struct SubjectManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    @State private var showAddSheet = false
    @State private var editingSubject: Subject?

    private let colorOptions: [(String, Color)] = [
        ("红色", .red), ("橙色", .orange), ("黄色", .yellow),
        ("绿色", .green), ("青色", .teal), ("蓝色", .blue),
        ("紫色", .purple), ("粉色", .pink), ("棕色", .brown),
    ]

    var body: some View {
        List {
            ForEach(subjects) { subject in
                HStack {
                    Circle()
                        .fill(subject.color)
                        .frame(width: 12, height: 12)

                    Text(subject.name)
                        .font(.body)

                    Spacer()

                    Button {
                        editingSubject = subject
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete(perform: deleteSubjects)
            .onMove(perform: moveSubjects)
        }
        .navigationTitle("科目管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            SubjectEditView(onSave: { name, colorHex in
                let newSubject = Subject(
                    name: name,
                    colorHex: colorHex,
                    sortOrder: (subjects.map(\.sortOrder).max() ?? -1) + 1
                )
                modelContext.insert(newSubject)
                try? modelContext.save()
            })
        }
        .sheet(item: $editingSubject) { subject in
            SubjectEditView(
                initialName: subject.name,
                initialColorHex: subject.colorHex,
                onSave: { name, colorHex in
                    subject.name = name
                    subject.colorHex = colorHex
                    try? modelContext.save()
                }
            )
        }
    }

    private func deleteSubjects(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subjects[index])
        }
        try? modelContext.save()
    }

    private func moveSubjects(from source: IndexSet, to destination: Int) {
        var ordered = subjects
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, subject) in ordered.enumerated() {
            subject.sortOrder = index
        }
        try? modelContext.save()
    }
}

// MARK: - Subject Edit Sheet

struct SubjectEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedColorHex: String

    let onSave: (String, String) -> Void

    private let colorOptions: [(String, String)] = [
        ("红色", "#E74C3C"), ("橙色", "#F39C12"), ("黄色", "#F1C40F"),
        ("绿色", "#2ECC71"), ("青色", "#1ABC9C"), ("蓝色", "#3498DB"),
        ("紫色", "#9B59B6"), ("粉色", "#E91E63"), ("棕色", "#5A5A40"),
    ]

    init(initialName: String = "", initialColorHex: String = "#3498DB",
         onSave: @escaping (String, String) -> Void) {
        _name = State(initialValue: initialName)
        _selectedColorHex = State(initialValue: initialColorHex)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("科目名称", text: $name)
                }

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.1) { label, hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .blue)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(name.isEmpty ? "新建科目" : "编辑科目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, selectedColorHex)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
