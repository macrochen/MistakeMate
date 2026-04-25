import Foundation
import SwiftData

@Model
final class ChatSession {
    var title: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]? = []

    init(title: String = "新对话") {
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
