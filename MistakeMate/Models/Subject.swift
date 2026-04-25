import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var name: String
    var colorHex: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Mistake.subject)
    var mistakes: [Mistake]? = []

    init(name: String, colorHex: String = "#5A5A40", sortOrder: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }

    static let defaultSubjects: [(name: String, color: String)] = [
        ("语文", "#E74C3C"),
        ("数学", "#3498DB"),
        ("英语", "#2ECC71"),
        ("物理", "#9B59B6"),
        ("化学", "#F39C12"),
        ("生物", "#1ABC9C"),
        ("历史", "#E67E22"),
        ("地理", "#27AE60"),
        ("政治", "#E91E63")
    ]

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}
