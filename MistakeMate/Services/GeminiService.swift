import Foundation
import SwiftData

/// AI analysis service using OpenAI-compatible API.
/// Keeps the prompt/result definitions from the original GeminiService,
/// but uses AIService as the transport layer.
struct AIServicePrompts {
    static let mistakeAnalysisPrompt = """
    你是一个极其专业的错题分析专家。请深度分析用户提供的图片或文字内容。

    核心任务：
    1. 识别图片中出现的错题内容。
    2. 判断学生的主要丢分点。
    3. 把丢分点对应到课本具体单元和知识点。
    4. 输出清晰的解题分析和正确答案。
    5. 生成一句防错提醒。
    6. 用苏格拉底式提问，一步步引导孩子自己走向正确解题。
    7. 语言风格适配学生年级理解能力。

    字段要求：
    - type: 不会 / 会但不熟 / 粗心 / 审题错 / 记忆错乱
    - textbookUnit: 课本具体单元
    - knowledgePoint: 具体知识点
    - scoreLossPoint: 主要丢分点
    - socraticQuestions: 3 到 5 个循序渐进的问题

    严格以 JSON 格式返回，包含一个 mistakes 数组。
    """
}

// MARK: - Result models

extension AIService {
    struct MistakeResult: Codable, Identifiable {
        var id: String { content + knowledgePoint + scoreLossPoint }

        let content: String
        let type: String
        let textbookUnit: String
        let knowledgePoint: String
        let scoreLossPoint: String
        let analysis: String
        let preventionRule: String
        let socraticQuestions: [String]
    }

    struct AnalyzeResponse: Codable {
        let mistakes: [MistakeResult]
    }

    /// Analyze mistakes from image
    func analyzeMistakes(
        imageData: Data,
        gradeLevel: String,
        textNote: String? = nil,
        baseURL: String,
        model: String,
        keychainKey: String
    ) async throws -> [MistakeResult] {
        let prompt = """
        当前学生年级：\(gradeLevel)
        \(textNote?.isEmpty == false ? "用户备注：\(textNote!)" : "请分析图片中的错题。")
        """

        let text = try await chat(
            message: prompt,
            imageData: imageData,
            systemInstruction: Self.mistakeAnalysisPrompt,
            baseURL: baseURL,
            model: model,
            keychainKey: keychainKey
        )

        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanedText.data(using: .utf8) else {
            throw AIError.parseError
        }

        return try JSONDecoder().decode(AnalyzeResponse.self, from: data).mistakes
    }
}

// MARK: - Keep prompt accessible from old location for backward compat

extension AIService {
    static let mistakeAnalysisPrompt = AIServicePrompts.mistakeAnalysisPrompt
}
