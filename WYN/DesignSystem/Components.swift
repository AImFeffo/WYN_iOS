import SwiftUI

/// Bottone primario "warm paper": pieno inchiostro, etichetta monospace maiuscola.
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.ink.opacity(isEnabled ? 1 : 0.35))
            .foregroundStyle(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Campo di testo con lo stile dell'app (superficie, hairline, padding coerente).
struct WYNTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.body(16))
        .foregroundStyle(Color.ink)
        .textInputAutocapitalization(autocapitalization)
        .autocorrectionDisabled()
        .keyboardType(keyboard)
        .textContentType(textContentType)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }
}

/// Icona categoria colorata dentro un tondo tenue (usata in card e dettaglio).
struct CategoryBadge: View {
    let category: Category
    var size: CGFloat = 40
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(category.color.opacity(colorScheme == .dark ? 0.22 : 0.14))
            Image(systemName: category.iconName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(category.color)
        }
        .frame(width: size, height: size)
    }
}

/// Campo "Evidenzia (facoltativo)" (max 150 char): etichetta mono, contatore, campo multilinea.
/// Senza bordo: è la seconda riga dell'AddBar, oppure va dentro una card nel sheet screenshot.
struct HighlightField: View {
    @Binding var text: String
    private let maxLength = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Evidenzia (facoltativo)")
                    .monoLabel(size: 9.5)
                    .foregroundStyle(Color.ink3)
                Spacer()
                if !text.isEmpty {
                    Text("\(text.count)/\(maxLength)")
                        .font(.mono(9.5))
                        .foregroundStyle(Color.ink3)
                }
            }
            TextField("Cosa vuoi evidenziare?", text: $text, axis: .vertical)
                .font(.body(14))
                .foregroundStyle(Color.ink)
                .lineLimit(1...3)
                .onChange(of: text) { _, v in
                    if v.count > maxLength { text = String(v.prefix(maxLength)) }
                }
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16))
    }
}

/// Tipo di fonte scritto ("Articolo" / "Screenshot") su riempimento tenue.
struct SourceTypeBadge: View {
    let sourceType: SourceType

    var body: some View {
        Text(sourceType == .article ? "Articolo" : "Screenshot")
            .monoLabel(size: 9)
            .foregroundStyle(Color.ink2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}
