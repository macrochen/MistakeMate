import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query private var settings: [AppSettings]
    @Query(sort: \Mistake.createdAt) private var allMistakes: [Mistake]

    var body: some View {
        NavigationStack {
            List {
                Section("学习档案") {
                    NavigationLink {
                        StudyProfileView()
                    } label: {
                        LabeledContent("当前年级", value: settings.first?.currentGrade ?? "未设置")
                    }
                }

                Section("科目管理") {
                    NavigationLink {
                        SubjectManageView()
                    } label: {
                        LabeledContent("科目数量", value: "\(subjects.count)")
                    }
                }

                Section("数据概览") {
                    LabeledContent("错题总数", value: "\(allMistakes.count)")
                    LabeledContent("科目数", value: "\(subjects.count)")
                }

                Section("AI") {
                    NavigationLink("Gemini API Key") {
                        APIKeySettingsView()
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "0.1.0")
                    LabeledContent("构建", value: "SwiftUI + SwiftData")
                }
            }
            .navigationTitle("设置")
        }
    }
}
