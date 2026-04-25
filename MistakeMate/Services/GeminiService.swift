import Foundation

struct GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.0-flash"

    private var apiKey: String? {
        try? KeychainService.shared.load(key: KeychainService.geminiKey)
    }

    func testConnection(apiKey: String) async throws -> Bool {
        let response = try await generateContent(
            prompt: "Hi",
            apiKeyOverride: apiKey,
            generationConfig: ["maxOutputTokens": 5]
        )
        return !response.isEmpty
    }

    func generateContent(
        prompt: String,
        imageData: Data? = nil,
        systemInstruction: String? = nil
    ) async throws -> String {
        try await generateContent(
            prompt: prompt,
            imageData: imageData,
            systemInstruction: systemInstruction,
            apiKeyOverride: nil,
            generationConfig: nil
        )
    }
}

extension GeminiService {
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

    func analyzeMistakes(imageData: Data, gradeLevel: String, textNote: String? = nil) async throws -> [MistakeResult] {
        let prompt = """
        当前学生年级：\(gradeLevel)
        \(textNote?.isEmpty == false ? "用户备注：\(textNote!)" : "请分析图片中的错题。")
        """

        let text = try await generateContent(
            prompt: prompt,
            imageData: imageData,
            systemInstruction: Self.mistakeAnalysisPrompt,
            apiKeyOverride: nil,
            generationConfig: ["responseMimeType": "application/json"]
        )

        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanedText.data(using: .utf8) else {
            throw GeminiError.parseError
        }

        return try JSONDecoder().decode(AnalyzeResponse.self, from: data).mistakes
    }

    func chat(
        message: String,
        history: [ChatHistorySnapshot],
        imageData: Data? = nil,
        systemInstruction: String? = nil
    ) async throws -> String {
        guard let key = apiKey else { throw GeminiError.noAPIKey }

        var contents: [[String: Any]] = []
        for item in history {
            let role = item.role == "assistant" ? "model" : "user"
            var parts: [[String: Any]] = [["text": item.content]]
            if let imageData = item.imageData {
                parts.append(inlineDataPart(imageData, mimeType: "image/jpeg"))
            }
            if let audioData = item.audioData {
                parts.append(inlineDataPart(audioData, mimeType: "audio/m4a"))
            }
            contents.append(["role": role, "parts": parts])
        }

        var currentParts: [[String: Any]] = [["text": message]]
        if let imageData {
            currentParts.append(inlineDataPart(imageData, mimeType: "image/jpeg"))
        }
        contents.append(["role": "user", "parts": currentParts])

        return try await sendGenerateContentRequest(
            apiKey: key,
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: nil
        )
    }
}

// MARK: - Sendable snapshot for chat history (Swift 6 concurrency safe)
struct ChatHistorySnapshot: Sendable {
    let role: String
    let content: String
    let imageData: Data?
    let audioData: Data?

    init(role: String, content: String, imageData: Data? = nil, audioData: Data? = nil) {
        self.role = role
        self.content = content
        self.imageData = imageData
        self.audioData = audioData
    }
}

private extension GeminiService {
    func generateContent(
        prompt: String,
        imageData: Data? = nil,
        systemInstruction: String? = nil,
        apiKeyOverride: String?,
        generationConfig: [String: Any]?
    ) async throws -> String {
        guard let key = apiKeyOverride?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? apiKey else {
            throw GeminiError.noAPIKey
        }

        var parts: [[String: Any]] = [["text": prompt]]
        if let imageData {
            parts.append(inlineDataPart(imageData, mimeType: "image/jpeg"))
        }

        return try await sendGenerateContentRequest(
            apiKey: key,
            contents: [["parts": parts]],
            systemInstruction: systemInstruction,
            generationConfig: generationConfig
        )
    }

    func sendGenerateContentRequest(
        apiKey: String,
        contents: [[String: Any]],
        systemInstruction: String?,
        generationConfig: [String: Any]?
    ) async throws -> String {
        guard let encodedKey = apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(encodedKey)") else {
            throw GeminiError.invalidURL
        }

        var body: [String: Any] = ["contents": contents]

        if let systemInstruction {
            body["systemInstruction"] = ["parts": [["text": systemInstruction]]]
        }

        if let generationConfig {
            body["generationConfig"] = generationConfig
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw GeminiError.httpError(httpResponse.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        return decoded.candidates.first?.content.parts.compactMap(\.text).joined(separator: "\n") ?? ""
    }

    func inlineDataPart(_ data: Data, mimeType: String) -> [String: Any] {
        [
            "inline_data": [
                "mime_type": mimeType,
                "data": data.base64EncodedString()
            ]
        ]
    }
}

private struct GeminiGenerateResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String?
    }
}

enum GeminiError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int, String?)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "请先在设置中配置 Gemini API Key"
        case .invalidURL:
            return "Gemini API 地址无效"
        case .invalidResponse:
            return "Gemini API 返回格式无效"
        case .httpError(let code, let message):
            if let message, !message.isEmpty {
                return "Gemini API 请求失败：HTTP \(code)\n\(message)"
            }
            return "Gemini API 请求失败：HTTP \(code)"
        case .parseError:
            return "AI 返回数据解析失败"
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
