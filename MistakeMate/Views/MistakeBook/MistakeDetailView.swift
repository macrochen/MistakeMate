import SwiftData
import SwiftUI

struct MistakeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mistake: Mistake

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageData = mistake.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        if let subject = mistake.subject {
                            Label(subject.name, systemImage: "circle.fill")
                                .foregroundStyle(subject.color)
                        }
                        Text(mistake.mistakeType)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    Text(mistake.content)
                        .font(.title3.weight(.semibold))
                        .textSelection(.enabled)
                }

                if let textbookUnit = mistake.textbookUnit, !textbookUnit.isEmpty {
                    infoBlock("教材单元", textbookUnit)
                }

                if let knowledgePoint = mistake.knowledgePoint, !knowledgePoint.isEmpty {
                    infoBlock("知识点", knowledgePoint)
                }

                if let scoreLossPoint = mistake.scoreLossPoint, !scoreLossPoint.isEmpty {
                    infoBlock("丢分点", scoreLossPoint)
                }

                infoBlock("解题分析", mistake.analysis)

                VStack(alignment: .leading, spacing: 8) {
                    Text("防错金句")
                        .font(.headline)
                    Text(mistake.preventionRule)
                        .font(.body.weight(.semibold))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !mistake.socraticQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("引导问题")
                            .font(.headline)
                        ForEach(mistake.socraticQuestions, id: \.self) { question in
                            Text("• \(question)")
                        }
                    }
                }

                if let source = mistake.source, !source.isEmpty {
                    infoBlock("来源", source)
                }
            }
            .padding()
        }
        .navigationTitle("错题详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    modelContext.delete(mistake)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }

    private func infoBlock(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
