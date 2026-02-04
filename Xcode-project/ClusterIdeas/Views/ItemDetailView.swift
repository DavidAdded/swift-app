import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: Item

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private var sortedFieldDefinitions: [FieldDefinition] {
        item.cluster.fieldDefinitions.sorted { $0.order < $1.order }
    }

    private var archivedFieldValues: [(String, String)] {
        let activeFieldNames = Set(sortedFieldDefinitions.map { $0.fieldName })
        return item.fieldValues
            .filter { !activeFieldNames.contains($0.key) }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    var body: some View {
        List {
            Section("Item Information") {
                Text("Created \(item.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Field Values") {
                ForEach(sortedFieldDefinitions) { field in
                    HStack {
                        Text(field.fieldName)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.fieldValues[field.fieldName].flatMap { $0.isEmpty ? nil : $0 } ?? "—")
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            if !archivedFieldValues.isEmpty {
                Section {
                    Text("These fields are no longer defined in the cluster but contain saved data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Archived Fields")
                }

                Section {
                    ForEach(archivedFieldValues, id: \.0) { fieldName, value in
                        HStack {
                            Text(fieldName)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(value.isEmpty ? "—" : value)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }

                Button {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete Item")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ItemFormView(cluster: item.cluster, existingItem: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete Item?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
