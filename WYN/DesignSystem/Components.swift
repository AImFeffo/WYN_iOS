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

    var body: some View {
        ZStack {
            Circle()
                .fill(category.color.opacity(0.14))
            Image(systemName: category.iconName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(category.color)
        }
        .frame(width: size, height: size)
    }
}
