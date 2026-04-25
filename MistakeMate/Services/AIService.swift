import Foundation
import SwiftData

// MARK: - OpenAI-Compatible AI Service

actor AIService {
    static let shared = AIService()

    // MARK: - Core: OpenAI-compatible Chat Completion

    func sendChatCompletion(
        baseURL: String,
        apiKey: String,
        model: String,
        messages: [[String: Any]],
        generationConfig: [String: Any]? = nil
    ) async throws -> String {
        let endpoint = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"

        guard let url = URL(string: endpoint) else {
            throw AIError.invalidURL
        }

        var body: [String: Any] = [
            "model": model,
            "messages": messages
        ]

        if let generationConfig {
            body.merge(generationConfig) { _, new in new }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw AIError.httpError(httpResponse.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        if let content = decoded.firstContent {
            return content
        }

        let rawResponse = String(data: data, encoding: .utf8)
        throw AIError.emptyResponse(rawResponse?.truncatedForDisplay())
    }

    // MARK: - Convenience: Build messages from history + current

    private func buildMessages(
        prompt: String,
        imageData: Data? = nil,
        history: [ChatHistorySnapshot] = []
    ) -> [[String: Any]] {
        var messages: [[String: Any]] = []

        for item in history {
            let hasAttachment = item.imageData != nil || item.audioData != nil
            if hasAttachment {
                // Use array format for multi-part messages (vision/audio)
                var parts: [[String: Any]] = [["type": "text", "text": item.content]]
                if let imageData = item.imageData {
                    parts.append(imageContentPart(imageData, mimeType: "image/jpeg"))
                }
                if let audioData = item.audioData {
                    parts.append(["type": "text", "text": "[Audio attachment: \(audioData.count) bytes]"])
                }
                messages.append(["role": item.role == "assistant" ? "assistant" : "user", "content": parts])
            } else {
                // Simple string format for text-only messages
                messages.append(["role": item.role == "assistant" ? "assistant" : "user", "content": item.content])
            }
        }

        // Current user message
        if let imageData {
            messages.append([
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    imageContentPart(imageData, mimeType: "image/jpeg")
                ] as [[String: Any]]
            ])
        } else {
            messages.append(["role": "user", "content": prompt])
        }

        return messages
    }

    private func imageContentPart(_ data: Data, mimeType: String) -> [String: Any] {
        [
            "type": "image_url",
            "image_url": ["url": "data:\(mimeType);base64,\(data.base64EncodedString())"]
        ]
    }

    // MARK: - Simple text generation

    func generateContent(
        prompt: String,
        systemInstruction: String? = nil,
        baseURL: String,
        model: String,
        keychainKey: String
    ) async throws -> String {
        guard let apiKey = try? KeychainService.shared.load(key: keychainKey), !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        var messages: [[String: Any]] = [["role": "user", "content": prompt]]
        if let systemInstruction {
            messages = [["role": "system", "content": systemInstruction]] + messages
        }

        return try await sendChatCompletion(
            baseURL: baseURL,
            apiKey: apiKey,
            model: model,
            messages: messages
        )
    }

    // MARK: - Chat with history + optional image/audio

    func chat(
        message: String,
        history: [ChatHistorySnapshot] = [],
        imageData: Data? = nil,
        systemInstruction: String? = nil,
        baseURL: String,
        model: String,
        keychainKey: String
    ) async throws -> String {
        guard let apiKey = try? KeychainService.shared.load(key: keychainKey), !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        var messages = buildMessages(prompt: message, imageData: imageData, history: history)
        if let systemInstruction {
            messages = [["role": "system", "content": systemInstruction]] + messages
        }

        return try await sendChatCompletion(
            baseURL: baseURL,
            apiKey: apiKey,
            model: model,
            messages: messages
        )
    }

    // MARK: - Test connection with explicit provider config

    func testConnection(apiKey: String, baseURL: String, model: String) async throws -> Bool {
        let response = try await sendChatCompletion(
            baseURL: baseURL,
            apiKey: apiKey,
            model: model,
            messages: [
                ["role": "user", "content": "Hi"]
            ],
            generationConfig: ["max_tokens": 5]
        )
        return !response.isEmpty
    }
}

// MARK: - Error types

enum AIError: LocalizedError {
    case noProvider
    case noAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int, String?)
    case emptyResponse(String?)
    case parseError
    case providerNotFound

    var errorDescription: String? {
        switch self {
        case .noProvider:
            return "未配置 AI 提供商，请先在设置中添加"
        case .noAPIKey:
            return "API Key 未配置或已失效"
        case .invalidURL:
            return "API 地址无效"
        case .invalidResponse:
            return "API 返回格式无效"
        case .httpError(let code, let message):
            if let message, !message.isEmpty {
                return "API 请求失败：HTTP \(code)\n\(message)"
            }
            return "API 请求失败：HTTP \(code)"
        case .emptyResponse(let rawResponse):
            if let rawResponse, !rawResponse.isEmpty {
                return "AI 返回了空内容。原始响应：\(rawResponse)"
            }
            return "AI 返回了空内容，请检查当前模型是否支持对话输出。"
        case .parseError:
            return "AI 返回数据解析失败"
        case .providerNotFound:
            return "未找到默认 AI 提供商"
        }
    }
}

// MARK: - Sendable snapshot (concurrency safe)

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

// MARK: - Response models

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    let usage: Usage?

    var firstContent: String? {
        for choice in choices {
            if let content = choice.message?.resolvedContent, !content.isBlank {
                return content
            }
            if let text = choice.text, !text.isBlank {
                return text
            }
        }
        return nil
    }

    struct Choice: Codable {
        let message: Message?
        let text: String?
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case text
            case finishReason = "finish_reason"
        }
    }

    struct Message: Codable {
        let content: MessageContent?
        let reasoningContent: String?

        enum CodingKeys: String, CodingKey {
            case content
            case reasoningContent = "reasoning_content"
        }

        var resolvedContent: String? {
            if let text = content?.text, !text.isBlank {
                return text
            }
            if let reasoningContent, !reasoningContent.isBlank {
                return reasoningContent
            }
            return nil
        }
    }

    enum MessageContent: Codable {
        case text(String)
        case parts([MessageContentPart])
        case empty

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .empty
            } else if let text = try? container.decode(String.self) {
                self = .text(text)
            } else if let parts = try? container.decode([MessageContentPart].self) {
                self = .parts(parts)
            } else {
                self = .empty
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let text):
                try container.encode(text)
            case .parts(let parts):
                try container.encode(parts)
            case .empty:
                try container.encodeNil()
            }
        }

        var text: String? {
            switch self {
            case .text(let text):
                return text
            case .parts(let parts):
                let combined = parts.compactMap(\.text).joined(separator: "\n")
                return combined.isBlank ? nil : combined
            case .empty:
                return nil
            }
        }
    }

    struct MessageContentPart: Codable {
        let type: String?
        let text: String?
    }

    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func truncatedForDisplay(limit: Int = 800) -> String {
        if count <= limit {
            return self
        }
        let end = index(startIndex, offsetBy: limit)
        return "\(self[..<end])..."
    }
}
