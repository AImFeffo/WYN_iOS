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

    /// Colore associato (§3). Variante dark schiarita per contrasto ≥ 3:1 (Asset Catalog).
    var color: Color {
        switch self {
        case .tech:     return Color("catTech")
        case .salute:   return Color("catSalute")
        case .business: return Color("catBusiness")
        case .cucina:   return Color("catCucina")
        case .design:   return Color("catDesign")
        case .finanza:  return Color("catFinanza")
        case .altro:    return Color("catAltro")
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
