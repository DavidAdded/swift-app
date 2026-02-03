import Foundation
import SwiftData

@Model
final class FieldDefinition {
    var id: UUID
    var fieldName: String
    var order: Int

    @Relationship(inverse: \Cluster.fieldDefinitions)
    var cluster: Cluster

    init(fieldName: String, order: Int, cluster: Cluster) {
        self.id = UUID()
        self.fieldName = fieldName
        self.order = order
        self.cluster = cluster
    }
}
