import SwiftUI
import SwiftData

struct ItemFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let cluster: Cluster
    let existingItem: Item?

    @State private var fieldValues: [String: String] = [:]
    @State private var isSaving = false
    @State private var attemptedSave = false

    private var sortedFieldDefinitions: [FieldDefinition] {
        cluster.fieldDefinitions.sorted { $0.order < $1.order }
    }

    private var isValid: Bool {
        fieldValues.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    ForEach(sortedFieldDefinitions) { field in
                        TextField(field.fieldName, text: binding(for: field.fieldName))
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                    }
                }

                if attemptedSave && !isValid {
                    Text("At least one field must have a value")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let existingItem {
                    Section("Item Information") {
                        Text("Created \(existingItem.createdAt.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "New Item" : "Edit Item")
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
                        if isValid {
                            saveItem()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .onAppear {
                if let existingItem {
                    fieldValues = existingItem.fieldValues
                }

                for field in sortedFieldDefinitions {
                    if fieldValues[field.fieldName] == nil {
                        fieldValues[field.fieldName] = ""
                    }
                }
            }
            .animation(.default, value: sortedFieldDefinitions.count)
        }
    }

    private func binding(for fieldName: String) -> Binding<String> {
        Binding(
            get: { fieldValues[fieldName, default: ""] },
            set: { fieldValues[fieldName] = $0 }
        )
    }

    private func saveItem() {
        isSaving = true

        let trimmedValues = fieldValues.mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if let existingItem {
            existingItem.fieldValues = trimmedValues
        } else {
            let item = Item(cluster: cluster, fieldValues: trimmedValues)
            modelContext.insert(item)
        }

        try? modelContext.save()
        dismiss()
    }
}
