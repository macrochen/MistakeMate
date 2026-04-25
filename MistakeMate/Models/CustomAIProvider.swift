import SwiftData
import Foundation

@Model
final class CustomAIProvider {
    var name: String             // 显示名称，如 "DeepSeek"、"OpenRouter"
    var baseURL: String          // https://api.deepseek.com/v1
    var apiKey: String           // 存 Keychain 引用键，实际密钥不存 SwiftData
    var model: String            // deepseek-chat 或 deepseek/deepseek-v4-pro-free
    var isDefault: Bool          // 是否默认提供商
    var createdAt: Date
    var updatedAt: Date

    init(name: String, baseURL: String, apiKey: String, model: String, isDefault: Bool = false) {
        self.name = name
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Stable Keychain key for this provider.
    /// Existing rows keep their stored Keychain reference even if the display name
    /// or endpoint changes. Older rows fall back to the legacy derived key.
    var keychainKey: String {
        if !apiKey.isEmpty {
            return apiKey
        }
        return "com.mistakemate.provider-\(name)-\(baseURL)"
    }

    var selectionKey: String {
        "\(name)|\(baseURL)|\(model)"
    }

    /// Normalized endpoint for display
    var displayEndpoint: String {
        baseURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/v1", with: "")
    }
}

// MARK: - Fetch helpers

extension CustomAIProvider {
    /// Fetch the default provider from SwiftData model context
    static func fetchDefault(in context: ModelContext) -> CustomAIProvider? {
        let descriptor = FetchDescriptor<CustomAIProvider>(
            predicate: #Predicate { $0.isDefault == true }
        )
        return try? context.fetch(descriptor).first
    }

    /// Fetch all providers
    static func fetchAll(in context: ModelContext) -> [CustomAIProvider] {
        let descriptor = FetchDescriptor<CustomAIProvider>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
