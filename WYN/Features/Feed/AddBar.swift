import SwiftUI

/// Barra di aggiunta in cima al feed. Con testo → bottone SALVA (link);
/// vuota → bottone fotocamera (apre il flusso screenshot).
struct AddBar: View {
    @Binding var linkText: String
    var isBusy: Bool
    var onSave: () -> Void
    var onCamera: () -> Void

    private var hasText: Bool { !linkText.trimmed.isEmpty }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Incolla un link…", text: $linkText)
                .font(.body(15))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.go)
                .onSubmit { if hasText { onSave() } }

            if hasText {
                Button(action: onSave) {
                    if isBusy {
                        ProgressView().tint(Color.surface).scaleEffect(0.8)
                    } else {
                        Text("Salva").monoLabel(size: 11, weight: .semibold)
                    }
                }
                .buttonStyle(.plain)
                .frame(minWidth: 60, minHeight: 40)
                .background(Color.ink)
                .foregroundStyle(Color.surface)
                .clipShape(Capsule())
                .disabled(isBusy)
            } else {
                Button(action: onCamera) {
                    Image(systemName: "camera")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: 52)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }
}
