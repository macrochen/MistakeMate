import Foundation
import SwiftData

@Model
final class AppSettings {
    var currentGrade: String
    var createdAt: Date
    var updatedAt: Date

    init(currentGrade: String = "未设置") {
        self.currentGrade = currentGrade
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
