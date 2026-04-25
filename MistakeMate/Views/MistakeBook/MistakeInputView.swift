import SwiftData
import SwiftUI

struct MistakeInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query private var settings: [AppSettings]

    @State private var selectedSubject: Subject?
    @State private var source = ""
    @State private var note = ""
    @State private var selectedImage: UIImage?
    @State private var compressedImageData: Data?
    @State private var picker: PickerKind?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var drafts: [DraftMistake] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    Picker("科目", selection: $selectedSubject) {
                        Text("请选择").tag(Optional<Subject>.none)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(Optional(subject))
                        }
                    }

                    TextField("来源，如期中卷 / 练习册", text: $source)
                    TextEditor(text: $note)
                        .frame(minHeight: 90)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("补充说明，可选")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }

                Section("图片") {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button(role: .destructive) {
                            self.selectedImage = nil
                            compressedImageData = nil
                        } label: {
                            Label("移除图片", systemImage: "xmark.circle")
                        }
                    } else {
                        ContentUnavailableView(
                            "添加错题图片",
                            systemImage: "photo.badge.plus",
                            description: Text("可以拍照或从相册选择。")
                        )
                    }

                    HStack {
                        Button {
                            picker = .camera
                        } label: {
                            Label("拍照", systemImage: "camera")
                        }
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                        Button {
                            picker = .photoLibrary
                        } label: {
                            Label("相册", systemImage: "photo")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await analyze() }
                    } label: {
                        if isAnalyzing {
                            Label("AI 正在识别错题...", systemImage: "sparkles")
                        } else {
                            Label("开始分析", systemImage: "sparkles")
                        }
                    }
                    .disabled(isAnalyzing || selectedSubject == nil || selectedImage == nil)
                }

                if !drafts.isEmpty {
                    Section("分析结果") {
                        ForEach($drafts) { $draft in
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("错误类型", text: $draft.type)
                                TextField("教材单元", text: $draft.textbookUnit)
                                TextField("知识点", text: $draft.knowledgePoint)
                                TextField("丢分点", text: $draft.scoreLossPoint)

                                Text("题目")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextEditor(text: $draft.content)
                                    .frame(minHeight: 90)

                                Text("分析")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextEditor(text: $draft.analysis)
                                    .frame(minHeight: 120)

                                TextField("防错金句", text: $draft.preventionRule, axis: .vertical)
                            }
                            .padding(.vertical, 8)
                        }

                        Button {
                            saveDrafts()
                        } label: {
                            Label("保存全部", systemImage: "tray.and.arrow.down")
                        }
                    }
                }
            }
            .navigationTitle("录入错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedSubject = selectedSubject ?? subjects.first
            }
            .onChange(of: selectedImage) { _, newValue in
                compressedImageData = newValue.flatMap { ImageProcessor.compress($0) }
            }
            .sheet(item: $picker) { picker in
                switch picker {
                case .camera:
                    ImagePicker(image: $selectedImage, sourceType: .camera)
                case .photoLibrary:
                    PhotoPicker(image: $selectedImage)
                }
            }
        }
    }

    private func analyze() async {
        guard let compressedImageData else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            let grade = settings.first?.currentGrade ?? "未设置"
            let results = try await GeminiService.shared.analyzeMistakes(
                imageData: compressedImageData,
                gradeLevel: grade,
                textNote: note
            )
            drafts = results.map(DraftMistake.init(result:))
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    private func saveDrafts() {
        guard let selectedSubject else { return }

        for draft in drafts {
            let mistake = Mistake(
                content: draft.content,
                mistakeType: draft.type,
                textbookUnit: draft.textbookUnit.nilIfBlank,
                knowledgePoint: draft.knowledgePoint.nilIfBlank,
                scoreLossPoint: draft.scoreLossPoint.nilIfBlank,
                analysis: draft.analysis,
                preventionRule: draft.preventionRule,
                socraticQuestions: draft.socraticQuestions,
                source: source.nilIfBlank,
                subject: selectedSubject,
                imageData: compressedImageData
            )
            modelContext.insert(mistake)
        }

        try? modelContext.save()
        dismiss()
    }
}

private enum PickerKind: Identifiable {
    case camera
    case photoLibrary

    var id: String {
        switch self {
        case .camera: "camera"
        case .photoLibrary: "photoLibrary"
        }
    }
}

private struct DraftMistake: Identifiable {
    let id = UUID()
    var content: String
    var type: String
    var textbookUnit: String
    var knowledgePoint: String
    var scoreLossPoint: String
    var analysis: String
    var preventionRule: String
    var socraticQuestions: [String]

    init(result: GeminiService.MistakeResult) {
        self.content = result.content
        self.type = result.type
        self.textbookUnit = result.textbookUnit
        self.knowledgePoint = result.knowledgePoint
        self.scoreLossPoint = result.scoreLossPoint
        self.analysis = result.analysis
        self.preventionRule = result.preventionRule
        self.socraticQuestions = result.socraticQuestions
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
