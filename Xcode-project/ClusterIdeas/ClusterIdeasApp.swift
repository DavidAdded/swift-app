import SwiftUI
import SwiftData

@main
struct ClusterIdeasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Cluster.self, FieldDefinition.self, Item.self])
    }
}
