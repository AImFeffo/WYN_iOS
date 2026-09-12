import SwiftUI

/// Barra di aggiunta in cima al feed, card unica a due righe.
/// Riga 1: campo link + "Salva" (con testo) oppure bottone fotocamera (vuoto).
/// Riga 2 (solo con testo): campo "Evidenzia (facoltativo)".
struct AddBar: View {
    @Binding var linkText: String
    @Binding var hint: String
    var isBusy: Bool
    var onSave: () -> Void
    var onCamera: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasText: Bool { !linkText.trimmed.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
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
                    .frame(minWidth: 64, minHeight: 40)
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
                            .background(Color.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .frame(minHeight: 52)

            if hasText {
                Rectangle().fill(Color.hairline).frame(height: 1)
                HighlightField(text: $hint)
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: hasText)
    }
}
