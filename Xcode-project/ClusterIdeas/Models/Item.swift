import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var createdAt: Date
    var fieldValuesData: Data?

    @Relationship(inverse: \Cluster.items)
    var cluster: Cluster

    var fieldValues: [String: String] {
        get {
            guard let fieldValuesData else {
                return [:]
            }
            return (try? JSONDecoder().decode([String: String].self, from: fieldValuesData)) ?? [:]
        }
        set {
            fieldValuesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(cluster: Cluster, fieldValues: [String: String] = [:]) {
        self.cluster = cluster
        self.id = UUID()
        self.createdAt = Date()
        self.fieldValuesData = nil
        self.fieldValues = fieldValues
    }
}
