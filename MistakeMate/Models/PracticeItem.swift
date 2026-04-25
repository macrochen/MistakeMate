import Foundation
import SwiftData

@Model
final class PracticeItem {
    var question: String
    var hint: String?
    var answer: String
    var explanation: String
    var difficulty: String
    var userAnswer: String?
    var isCompleted: Bool
    var sortOrder: Int

    @Relationship
    var practiceSet: PracticeSet?

    init(
        question: String,
        hint: String? = nil,
        answer: String,
        explanation: String,
        difficulty: String,
        sortOrder: Int = 0,
        practiceSet: PracticeSet? = nil
    ) {
        self.question = question
        self.hint = hint
        self.answer = answer
        self.explanation = explanation
        self.difficulty = difficulty
        self.userAnswer = nil
        self.isCompleted = false
        self.sortOrder = sortOrder
        self.practiceSet = practiceSet
    }
}
