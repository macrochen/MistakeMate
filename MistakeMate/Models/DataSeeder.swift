import Foundation
import SwiftData

struct DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Subject>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }

        for (index, subject) in Subject.defaultSubjects.enumerated() {
            let model = Subject(name: subject.name, colorHex: subject.color, sortOrder: index)
            context.insert(model)
        }

        if (try? context.fetchCount(FetchDescriptor<AppSettings>())) == 0 {
            context.insert(AppSettings())
        }

        try? context.save()
    }
}
