import Foundation
import SwiftData

@Model
final class Cluster {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var fieldDefinitions: [FieldDefinition]

    @Relationship(deleteRule: .cascade)
    var items: [Item]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.fieldDefinitions = []
        self.items = []
    }
}
