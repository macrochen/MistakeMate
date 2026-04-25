import Foundation
import SwiftData

@Model
final class ChatMessage {
    var role: String
    var content: String
    var imageData: Data?
    var audioData: Data?
    var audioDuration: Double?
    var createdAt: Date

    @Relationship
    var session: ChatSession?

    init(
        role: String,
        content: String,
        session: ChatSession? = nil,
        imageData: Data? = nil,
        audioData: Data? = nil,
        audioDuration: Double? = nil
    ) {
        self.role = role
        self.content = content
        self.session = session
        self.imageData = imageData
        self.audioData = audioData
        self.audioDuration = audioDuration
        self.createdAt = Date()
    }
}
