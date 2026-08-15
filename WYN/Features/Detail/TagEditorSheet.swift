import SwiftUI

/// Normalizzazione tag (§6.4): trim, minuscolo, ≤40 char, non vuoti, deduplicati.
enum TagNormalizer {
    static func normalize(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in tags {
            let t = String(raw.trimmed.lowercased().prefix(40))
            guard !t.isEmpty, !seen.contains(t) else { continue }
            seen.insert(t)
            result.append(t)
        }
        return result
    }
}

/// Sheet per modificare i tag di una nota.
struct TagEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tags: [String]
    @State private var newTag = ""
    let onSave: ([String]) -> Void

    init(tags: [String], onSave: @escaping ([String]) -> Void) {
        _tags = State(initialValue: tags)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        TextField("Nuovo tag", text: $newTag)
                            .font(.body(15))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(addTag)
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1))
                        Button(action: addTag) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.surface)
                                .frame(width: 46, height: 46)
                                .background(Color.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(newTag.trimmed.isEmpty)
                    }

                    editableTags
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Modifica tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        onSave(TagNormalizer.normalize(tags))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var editableTags: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 6) {
                    Text(tag).font(.mono(12, weight: .medium)).foregroundStyle(Color.ink)
                    Button {
                        tags.removeAll { $0 == tag }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.ink3)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.ink.opacity(0.05))
                .clipShape(Capsule())
            }
        }
    }

    private func addTag() {
        let t = newTag.trimmed
        guard !t.isEmpty else { return }
        tags.append(t)
        newTag = ""
    }
}

/// Mostra i tag di sola lettura in un flow layout.
struct FlowTags: View {
    let tags: [String]
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.mono(12, weight: .medium))
                    .foregroundStyle(Color.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.ink.opacity(0.05))
                    .clipShape(Capsule())
            }
        }
    }
}
