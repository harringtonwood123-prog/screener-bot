import SwiftUI
import PhotosUI
import UIKit

/// Scan flow: take or pick a photo, let Vision guess the type and colour,
/// then confirm. Everything is editable, and the photo is optional.
struct AddGarmentView: View {
    @Environment(WardrobeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var photo: UIImage?
    @State private var showingCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var isScanning = false

    @State private var kind: GarmentKind = .tShirt
    @State private var name: String = ""
    @State private var colorHex: String = "#8E8E93"
    @State private var didAutoDetect = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoArea
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("What is it?") {
                    // GarmentKind.allCases is declared in slot order, so this
                    // list already reads tops -> bottoms -> outerwear -> shoes.
                    Picker("Type", selection: $kind) {
                        ForEach(GarmentKind.allCases) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                }

                Section("Colour") {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: colorHex))
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                            )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(HSBColor(hex: colorHex).name.capitalizedFirst)
                                .font(.headline)
                            Text(didAutoDetect ? "Picked out from your photo" : "Tap to change")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ColorPicker("", selection: colorBinding, supportsOpacity: false)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text("We use the type and colour to work out what this goes with and how warm it is. You can change any of it later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addGarment() }
                        .disabled(isScanning)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    photo = image
                    Task { await scan(image) }
                }
                .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photo = image
                        await scan(image)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var photoArea: some View {
        VStack(spacing: 14) {
            ZStack {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.tertiarySystemFill)
                    VStack(spacing: 8) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 38))
                        Text("Add a photo (optional)")
                            .font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }

                if isScanning {
                    Color.black.opacity(0.35)
                    VStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Reading the colour…")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 210)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 12) {
                if CameraPicker.isAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Scan", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: colorHex) },
            set: { newValue in
                didAutoDetect = false
                colorHex = hex(from: newValue)
            }
        )
    }

    private func hex(from color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return colorHex }
        return HSBColor(red: Double(r), green: Double(g), blue: Double(b)).hex
    }

    private func scan(_ image: UIImage) async {
        isScanning = true
        let result = await GarmentScanner.scan(image)
        colorHex = result.primaryHex
        didAutoDetect = true
        if let suggested = result.suggestedKind {
            kind = suggested
            if name.isEmpty {
                name = "\(HSBColor(hex: result.primaryHex).name.capitalizedFirst) \(suggested.displayName.lowercased())"
            }
        }
        isScanning = false
    }

    private func addGarment() {
        let filename = photo.flatMap { ImageStore.save($0) }
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        store.add(
            Garment(
                kind: kind,
                name: finalName.isEmpty
                    ? "\(HSBColor(hex: colorHex).name.capitalizedFirst) \(kind.displayName.lowercased())"
                    : finalName,
                colorHex: colorHex,
                imageFilename: filename
            )
        )
        dismiss()
    }
}
