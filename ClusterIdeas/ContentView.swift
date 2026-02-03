import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clusters: [Cluster]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Clusters: \(clusters.count)")
                }
            }
            .navigationTitle("Clusters")
        }
    }
}
