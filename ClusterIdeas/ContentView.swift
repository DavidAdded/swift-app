import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cluster.createdAt, order: .reverse) private var clusters: [Cluster]
    @State private var showingCreateCluster = false

    var body: some View {
        NavigationStack {
            Group {
                if clusters.isEmpty {
                    ContentUnavailableView(
                        "No Clusters",
                        systemImage: "square.stack.3d.up",
                        description: Text("Create your first cluster to get started")
                    ) {
                        Button("Create Cluster") {
                            showingCreateCluster = true
                        }
                    }
                } else {
                    List {
                        ForEach(clusters) { cluster in
                            NavigationLink(value: cluster) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cluster.name)

                                    HStack(spacing: 4) {
                                        Text("\(cluster.fieldDefinitions.count) fields")
                                        Text("•")
                                        Text("\(cluster.items.count) items")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    Text(cluster.createdAt.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(cluster)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clusters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateCluster = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCluster) {
                CreateClusterView()
            }
            .navigationDestination(for: Cluster.self) { cluster in
                ClusterDetailView(cluster: cluster)
            }
        }
    }
}
