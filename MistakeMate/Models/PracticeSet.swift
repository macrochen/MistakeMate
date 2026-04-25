import Foundation
import SwiftData

@Model
final class PracticeSet {
    var title: String
    var gradeSnapshot: String
    var status: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship
    var mistake: Mistake?

    @Relationship(deleteRule: .cascade, inverse: \PracticeItem.practiceSet)
    var items: [PracticeItem]? = []

    init(title: String, gradeSnapshot: String, status: String = "未开始", mistake: Mistake? = nil) {
        self.title = title
        self.gradeSnapshot = gradeSnapshot
        self.status = status
        self.mistake = mistake
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
