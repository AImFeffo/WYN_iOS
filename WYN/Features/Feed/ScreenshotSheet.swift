import SwiftUI
import UIKit

/// Bottom sheet "Carica screenshot": scelta tra Libreria e Fotocamera, con hint opzionale.
/// Alla scelta di un'immagine chiama `onImage(image, hint)`.
struct ScreenshotSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onImage: (UIImage, String?) -> Void

    @State private var hint = ""
    @State private var showLibrary = false
    @State private var showCamera = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Carica screenshot")
                .font(.heading(24, weight: .medium))
                .foregroundStyle(Color.ink)
                .padding(.top, 8)

            HintField(hint: $hint)

            VStack(spacing: 12) {
                optionButton(icon: "photo.on.rectangle", label: "Scegli da Libreria") {
                    showLibrary = true
                }
                optionButton(icon: "camera", label: "Scatta foto",
                             enabled: cameraAvailable) {
                    showCamera = true
                }
            }

            if !cameraAvailable {
                Text("La fotocamera non è disponibile su questo dispositivo.")
                    .font(.body(12))
                    .foregroundStyle(Color.ink3)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.bg.ignoresSafeArea())
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showLibrary) {
            LibraryPicker { image in deliver(image) }
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in deliver(image) }
                .ignoresSafeArea()
        }
    }

    private func deliver(_ image: UIImage) {
        let h = hint.trimmed
        onImage(image, h.isEmpty ? nil : h)
        dismiss()
    }

    private func optionButton(icon: String, label: String, enabled: Bool = true,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24)
                Text(label).font(.body(16, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ink3)
            }
            .foregroundStyle(enabled ? Color.ink : Color.ink3)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Campo hint opzionale "Cosa vuoi evidenziare?" (max 150 char).
struct HintField: View {
    @Binding var hint: String
    private let maxLength = 150

    var body: some View {
        TextField("Cosa vuoi evidenziare? (facoltativo)", text: $hint, axis: .vertical)
            .font(.body(15))
            .foregroundStyle(Color.ink)
            .lineLimit(1...3)
            .onChange(of: hint) { _, v in
                if v.count > maxLength { hint = String(v.prefix(maxLength)) }
            }
            .padding(14)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1))
    }
}
