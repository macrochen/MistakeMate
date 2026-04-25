import Foundation
import SwiftData

@Model
final class PromptTemplate {
    var title: String
    var content: String
    var category: String
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?

    init(title: String, content: String, category: String = "我的定制") {
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastUsedAt = nil
    }
}
