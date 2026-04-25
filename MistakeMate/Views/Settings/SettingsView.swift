import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query private var settings: [AppSettings]

    var body: some View {
        List {
            Section("学习档案") {
                LabeledContent("当前年级", value: settings.first?.currentGrade ?? "未设置")
            }

            Section("科目管理") {
                ForEach(subjects) { subject in
                    Label(subject.name, systemImage: "circle.fill")
                        .foregroundStyle(subject.color)
                }
            }

            Section("AI") {
                NavigationLink("Gemini API Key") {
                    APIKeySettingsView()
                }
            }

            Section("关于") {
                LabeledContent("版本", value: "0.1.0")
            }
        }
        .navigationTitle("设置")
    }
}
