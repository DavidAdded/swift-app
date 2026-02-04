import SwiftUI
import SwiftData

struct CreateClusterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var clusterName = ""
    @State private var fieldDefinitions: [String] = [""]
    @State private var attemptedSave = false
    @FocusState private var focusedField: FocusField?

    private enum FocusField: Hashable {
        case clusterName
    }

    private var trimmedClusterName: String {
        clusterName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedFieldDefinitions: [String] {
        fieldDefinitions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var isSaveDisabled: Bool {
        trimmedClusterName.isEmpty || trimmedFieldDefinitions.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cluster Details") {
                    TextField("Cluster Name", text: $clusterName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .clusterName)

                    if (attemptedSave || focusedField != .clusterName) && trimmedClusterName.isEmpty {
                        Text("Cluster name is required")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Field Definitions") {
                    ForEach(fieldDefinitions.indices, id: \.self) { index in
                        HStack {
                            TextField("Field name", text: $fieldDefinitions[index])
                                .textInputAutocapitalization(.words)
                                .submitLabel(.next)

                            if fieldDefinitions.count > 1 {
                                Button {
                                    fieldDefinitions.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove field")
                            }
                        }
                    }

                    Button("Add Field") {
                        fieldDefinitions.append("")
                    }

                    if attemptedSave && trimmedFieldDefinitions.isEmpty {
                        Text("At least one field is required")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Cluster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        attemptedSave = true
                        if !isSaveDisabled {
                            saveCluster()
                        }
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func saveCluster() {
        let cluster = Cluster(name: trimmedClusterName)
        modelContext.insert(cluster)

        for (index, fieldName) in trimmedFieldDefinitions.enumerated() {
            let fieldDefinition = FieldDefinition(fieldName: fieldName, order: index, cluster: cluster)
            modelContext.insert(fieldDefinition)
        }

        dismiss()
    }
}
