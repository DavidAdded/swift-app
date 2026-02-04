import SwiftUI
import SwiftData

struct ClusterDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var cluster: Cluster

    @State private var isEditing = false
    @State private var editableClusterName = ""
    @State private var editableFieldDefinitions: [EditableFieldDefinition] = []
    @State private var newFieldName = ""
    @State private var showingFieldDeleteAlert = false
    @State private var pendingFieldDeletion: EditableFieldDefinition?
    @State private var showingCreateItem = false
    @State private var editMode: EditMode = .inactive

    private var trimmedClusterName: String {
        editableClusterName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDoneDisabled: Bool {
        trimmedClusterName.isEmpty || editableFieldDefinitions.contains { $0.trimmedName.isEmpty }
    }

    private var sortedFieldDefinitions: [FieldDefinition] {
        cluster.fieldDefinitions.sorted { $0.order < $1.order }
    }

    private var sortedItems: [Item] {
        cluster.items.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section("Cluster Info") {
                if isEditing {
                    TextField("Cluster Name", text: $editableClusterName)

                    if trimmedClusterName.isEmpty {
                        Text("Name cannot be empty")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else {
                    Text(cluster.name)
                        .font(.title2)
                }

                Text("Created \(cluster.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(cluster.fieldDefinitions.count) fields • \(cluster.items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Field Definitions") {
                if isEditing {
                    ForEach($editableFieldDefinitions) { $field in
                        HStack {
                            TextField("Field name", text: $field.name)

                            if field.trimmedName.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .accessibilityLabel("Field name cannot be empty")
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(field.trimmedName.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                        )
                    }
                    .onMove(perform: moveFieldDefinitions)
                    .onDelete(perform: deleteFieldDefinitions)

                    HStack {
                        TextField("Field name", text: $newFieldName)
                        Button("Add Field") {
                            addFieldDefinition()
                        }
                        .disabled(newFieldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .transition(.move(edge: .trailing))
                } else {
                    ForEach(sortedFieldDefinitions) { field in
                        HStack {
                            Text("\(field.order + 1).")
                                .foregroundStyle(.secondary)
                            Text(field.fieldName)
                        }
                    }
                }
            }

            Section {
                if sortedItems.isEmpty {
                    VStack(spacing: 12) {
                        ContentUnavailableView(
                            "No Items",
                            systemImage: "tray",
                            description: Text("Add your first item to this cluster")
                        )

                        Button("Add Item") {
                            showingCreateItem = true
                        }
                    }
                } else {
                    ForEach(sortedItems) { item in
                        NavigationLink(value: item) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(itemPreview(for: item))

                                Text("Item created \(item.createdAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Items")
                    Spacer()
                    Button {
                        showingCreateItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(cluster.name)
        .environment(\.editMode, $editMode)
        .animation(.default, value: isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveChanges()
                    }
                    .disabled(isDoneDisabled)
                    .help(isDoneDisabled ? "Fix validation errors to enable saving." : "")
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
        }
        .alert(
            "Items contain data for this field. Deleting will preserve existing data but hide this field.",
            isPresented: $showingFieldDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                confirmFieldDeletion()
            }
            Button("Cancel", role: .cancel) {
                pendingFieldDeletion = nil
            }
        }
        .sheet(isPresented: $showingCreateItem) {
            ItemFormView(cluster: cluster, existingItem: nil)
        }
        .navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
    }

    private func startEditing() {
        withAnimation {
            editableClusterName = cluster.name
            editableFieldDefinitions = cluster.fieldDefinitions
                .sorted { $0.order < $1.order }
                .map { field in
                    EditableFieldDefinition(
                        id: field.id,
                        existingId: field.id,
                        name: field.fieldName,
                        order: field.order,
                        originalName: field.fieldName
                    )
                }
            isEditing = true
            editMode = .active
        }
    }

    private func cancelEditing() {
        withAnimation {
            editableClusterName = cluster.name
            editableFieldDefinitions = cluster.fieldDefinitions
                .sorted { $0.order < $1.order }
                .map { field in
                    EditableFieldDefinition(
                        id: field.id,
                        existingId: field.id,
                        name: field.fieldName,
                        order: field.order,
                        originalName: field.fieldName
                    )
                }
            newFieldName = ""
            pendingFieldDeletion = nil
            isEditing = false
            editMode = .inactive
        }
    }

    private func saveChanges() {
        cluster.name = trimmedClusterName

        let existingFieldsById = Dictionary(
            uniqueKeysWithValues: cluster.fieldDefinitions.map { ($0.id, $0) }
        )

        let editedExistingIds = Set(editableFieldDefinitions.compactMap { $0.existingId })
        let fieldsToDelete = cluster.fieldDefinitions.filter { !editedExistingIds.contains($0.id) }
        for field in fieldsToDelete {
            modelContext.delete(field)
        }

        for (index, editableField) in editableFieldDefinitions.enumerated() {
            let trimmedName = editableField.trimmedName
            if let existingId = editableField.existingId, let field = existingFieldsById[existingId] {
                field.fieldName = trimmedName
                field.order = index
            } else {
                let newField = FieldDefinition(
                    fieldName: trimmedName,
                    order: index,
                    cluster: cluster
                )
                modelContext.insert(newField)
            }
        }

        try? modelContext.save()
        isEditing = false
        editMode = .inactive
    }

    private func addFieldDefinition() {
        let trimmedName = newFieldName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newField = EditableFieldDefinition(
            id: UUID(),
            existingId: nil,
            name: trimmedName,
            order: editableFieldDefinitions.count,
            originalName: nil
        )
        editableFieldDefinitions.append(newField)
        newFieldName = ""
    }

    private func deleteFieldDefinitions(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let fieldToDelete = editableFieldDefinitions[index]

        let hasItemData = cluster.items.contains { item in
            item.fieldValues.keys.contains(fieldToDelete.originalName ?? fieldToDelete.name)
        }

        if hasItemData {
            pendingFieldDeletion = fieldToDelete
            showingFieldDeleteAlert = true
        } else {
            removeFieldDefinition(fieldToDelete)
        }
    }

    private func confirmFieldDeletion() {
        guard let fieldToDelete = pendingFieldDeletion else { return }
        removeFieldDefinition(fieldToDelete)
        pendingFieldDeletion = nil
    }

    private func removeFieldDefinition(_ field: EditableFieldDefinition) {
        editableFieldDefinitions.removeAll { $0.id == field.id }
        for (index, field) in editableFieldDefinitions.enumerated() {
            editableFieldDefinitions[index].order = index
        }
    }

    private func moveFieldDefinitions(from source: IndexSet, to destination: Int) {
        editableFieldDefinitions.move(fromOffsets: source, toOffset: destination)
        for (index, _) in editableFieldDefinitions.enumerated() {
            editableFieldDefinitions[index].order = index
        }
    }

    private func itemPreview(for item: Item) -> String {
        let orderedFieldNames = sortedFieldDefinitions.map { $0.fieldName }
        let values = orderedFieldNames.compactMap { item.fieldValues[$0] }

        if values.isEmpty {
            return "No fields"
        }

        return values.prefix(2).joined(separator: " • ")
    }
}

private struct EditableFieldDefinition: Identifiable, Equatable {
    let id: UUID
    let existingId: UUID?
    var name: String
    var order: Int
    let originalName: String?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
