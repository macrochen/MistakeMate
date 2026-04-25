import SwiftData
import SwiftUI

struct StudyProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    @State private var selectedGrade: String
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let grades = ["未设置", "一年级", "二年级", "三年级", "四年级", "五年级", "六年级",
                          "七年级", "八年级", "九年级",
                          "高一", "高二", "高三"]

    init() {
        _selectedGrade = State(initialValue: "")
    }

    var body: some View {
        Form {
            Section("当前年级") {
                Picker("年级", selection: $selectedGrade) {
                    ForEach(grades, id: \.self) { grade in
                        Text(grade).tag(grade)
                    }
                }

                Text("年级设置将影响 AI 错题分析和题目生成的语言难度。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        Text("保存")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(currentSettings?.currentGrade == selectedGrade)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#5A5A40") ?? .brown)
            }
        }
        .navigationTitle("学习档案")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedGrade = currentSettings?.currentGrade ?? "未设置"
        }
        .alert("学习档案", isPresented: $showAlert) {
            Button("好") { }
        } message: {
            Text(alertMessage)
        }
    }

    private var currentSettings: AppSettings? {
        settings.first
    }

    private func save() {
        if let existing = currentSettings {
            existing.currentGrade = selectedGrade
            existing.updatedAt = Date()
        } else {
            let new = AppSettings(currentGrade: selectedGrade)
            modelContext.insert(new)
        }
        try? modelContext.save()
        alertMessage = "年级已更新为" + selectedGrade
        showAlert = true
    }
}
