import Foundation
import SwiftData

@Model
final class Mistake {
    var content: String
    var mistakeType: String
    var textbookUnit: String?
    var knowledgePoint: String?
    var scoreLossPoint: String?
    var analysis: String
    var preventionRule: String
    var socraticQuestions: [String]
    var source: String?
    var notes: String?
    var imageData: Data?
    var createdAt: Date
    var updatedAt: Date

    @Relationship
    var subject: Subject?

    static let mistakeTypes = [
        "不会",
        "会但不熟",
        "粗心",
        "审题错",
        "记忆错乱"
    ]

    init(
        content: String,
        mistakeType: String,
        textbookUnit: String? = nil,
        knowledgePoint: String? = nil,
        scoreLossPoint: String? = nil,
        analysis: String,
        preventionRule: String,
        socraticQuestions: [String] = [],
        source: String? = nil,
        subject: Subject? = nil,
        imageData: Data? = nil
    ) {
        self.content = content
        self.mistakeType = mistakeType
        self.textbookUnit = textbookUnit
        self.knowledgePoint = knowledgePoint
        self.scoreLossPoint = scoreLossPoint
        self.analysis = analysis
        self.preventionRule = preventionRule
        self.socraticQuestions = socraticQuestions
        self.source = source
        self.subject = subject
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
