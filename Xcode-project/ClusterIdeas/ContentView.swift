import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cluster.createdAt, order: .reverse) private var clusters: [Cluster]
    @State private var showingCreateCluster = false
    @State private var showingDeleteAlert = false
    @State private var pendingDeleteCluster: Cluster?

    var body: some View {
        NavigationStack {
            Group {
                if clusters.isEmpty {
                    VStack(spacing: 12) {
                        ContentUnavailableView(
                            "No Clusters",
                            systemImage: "square.stack.3d.up",
                            description: Text("Create your first cluster to get started")
                        )

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
                            .transition(.opacity.combined(with: .scale))
                            .swipeActions {
                                Button(role: .destructive) {
                                    pendingDeleteCluster = cluster
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .animation(.default, value: clusters)
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
            .refreshable {
                _ = clusters.count
            }
            .navigationDestination(for: Cluster.self) { cluster in
                ClusterDetailView(cluster: cluster)
            }
            .alert("Delete Cluster?", isPresented: $showingDeleteAlert, presenting: pendingDeleteCluster) { cluster in
                Button("Delete", role: .destructive) {
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    modelContext.delete(cluster)
                    try? modelContext.save()
                    pendingDeleteCluster = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteCluster = nil
                }
            } message: { cluster in
                if cluster.items.isEmpty {
                    Text("This action cannot be undone.")
                } else {
                    Text("This will delete \(cluster.items.count) item(s). This action cannot be undone.")
                }
            }
        }
    }
}
