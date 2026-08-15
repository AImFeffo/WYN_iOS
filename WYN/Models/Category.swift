import SwiftUI

/// Le 7 categorie fisse di WYN (§3), con colore e icona associati.
///
/// Se una nota ha una categoria non riconosciuta, si usa `.altro`
/// (fallback grigio `#8C8478`).
enum Category: String, CaseIterable, Identifiable, Sendable {
    case tech = "Tech"
    case salute = "Salute"
    case business = "Business"
    case cucina = "Cucina"
    case design = "Design"
    case finanza = "Finanza"
    case altro = "Altro"

    var id: String { rawValue }

    /// Nome mostrato in UI (coincide col valore salvato nel DB).
    var displayName: String { rawValue }

    /// Colore associato (§3).
    var color: Color {
        switch self {
        case .tech:     return Color(hex: 0x2C5266)
        case .salute:   return Color(hex: 0x5E7E6B)
        case .business: return Color(hex: 0xB0884A)
        case .cucina:   return Color(hex: 0xAE5F3D)
        case .design:   return Color(hex: 0x6E5E84)
        case .finanza:  return Color(hex: 0x3B5A52)
        case .altro:    return Color(hex: 0x8C8478)
        }
    }

    /// Icona SF Symbol sobria, in linea con l'estetica editoriale.
    var iconName: String {
        switch self {
        case .tech:     return "cpu"
        case .salute:   return "heart"
        case .business: return "briefcase"
        case .cucina:   return "fork.knife"
        case .design:   return "paintbrush.pointed"
        case .finanza:  return "chart.line.uptrend.xyaxis"
        case .altro:    return "square.grid.2x2"
        }
    }

    /// Mappa una stringa categoria (dal DB) alla categoria nota, con fallback.
    static func from(_ raw: String) -> Category {
        Category(rawValue: raw) ?? .altro
    }
}
