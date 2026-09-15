import SwiftUI

/// Everything the user owns, grouped by where it goes on the body.
struct ClosetView: View {
    @Environment(WardrobeStore.self) private var store
    @State private var adding = false
    @State private var editing: Garment?

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if store.garments.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(GarmentSlot.allCases) { slot in
                                let items = store.garments(in: slot)
                                if !items.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(slot.title) · \(items.count)")
                                            .font(.headline)
                                        LazyVGrid(columns: columns, spacing: 12) {
                                            ForEach(items) { garment in
                                                Button { editing = garment } label: {
                                                    VStack(spacing: 6) {
                                                        GarmentThumb(garment: garment, size: 96)
                                                        Text(garment.name)
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                            .lineLimit(2)
                                                            .multilineTextAlignment(.center)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $adding) { AddGarmentView() }
            .sheet(item: $editing) { garment in
                GarmentDetailView(garment: garment)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Nothing here yet")
                .font(.title3.bold())
            Text("Scan a piece of clothing and we'll work out what it is and what colour it is.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                adding = true
            } label: {
                Label("Add your first item", systemImage: "camera.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// Tap a garment to rename it, tweak it, or throw it out.
struct GarmentDetailView: View {
    @Environment(WardrobeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Garment
    @State private var confirmingDelete = false

    init(garment: Garment) {
        _draft = State(initialValue: garment)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        GarmentThumb(garment: draft, size: 140)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Details") {
                    TextField("Name", text: $draft.name)
                    Picker("Type", selection: $draft.kind) {
                        ForEach(GarmentKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    LabeledContent("Colour", value: draft.color.name.capitalizedFirst)
                }

                Section("Behaviour") {
                    Toggle("Favourite", isOn: $draft.isFavourite)
                    Toggle("Water resistant", isOn: $draft.isWaterResistant)
                    Stepper(
                        "Warmth: \(draft.warmth)",
                        value: Binding(
                            get: { draft.warmthOverride ?? draft.kind.warmth },
                            set: { draft.warmthOverride = $0 }
                        ),
                        in: 0...5
                    )
                }

                Section {
                    Button("Remove from closet", role: .destructive) {
                        confirmingDelete = true
                    }
                }
            }
            .navigationTitle(draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.update(draft)
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Remove \(draft.name)?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    store.delete(draft)
                    dismiss()
                }
                Button("Keep it", role: .cancel) { }
            }
        }
    }
}
