import SwiftUI

/// Tipografia del design system (§7):
/// - Titoli: Newsreader (serif), tracking negativo.
/// - Testo: Geist (sans).
/// - Etichette / meta: Geist Mono, spesso maiuscolo con letter-spacing.
extension Font {
    /// Titolo serif (Newsreader).
    static func heading(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .custom("Newsreader", size: size).weight(weight)
    }

    /// Testo corpo (Geist).
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Geist", size: size).weight(weight)
    }

    /// Etichette / meta (Geist Mono).
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Geist Mono", size: size).weight(weight)
    }
}

/// Stile testuale per etichette monospace maiuscole con letter-spacing (byline, chip, meta).
struct MonoLabel: ViewModifier {
    var size: CGFloat = 12
    var weight: Font.Weight = .medium
    func body(content: Content) -> some View {
        content
            .font(.mono(size, weight: weight))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

extension View {
    func monoLabel(size: CGFloat = 12, weight: Font.Weight = .medium) -> some View {
        modifier(MonoLabel(size: size, weight: weight))
    }
}
