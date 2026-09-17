import SwiftUI

/// Token semantici del design system "warm paper" (§7).
/// I valori light/dark sono definiti nell'Asset Catalog.
extension Color {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let ink = Color("ink")
    static let ink2 = Color("ink2")
    static let ink3 = Color("ink3")
    static let hairline = Color("hairline")
    static let hairlineStrong = Color("hairlineStrong")
    static let danger = Color("danger")
    /// Ex valore di `ink3`: solo glifi (chevron, ×) e divisori. Mai per testo.
    static let inkDecor = Color("inkDecor")
    /// Sfondo del termine trovato in ricerca (oro Business al 32% / 40%).
    static let match = Color("match")
    /// Riempimento tenue di tag, badge e bottoni secondari (ink al 5% / 7%).
    static let fill = Color("fill")
    /// Colore di avanzamento della card "in arrivo".
    static let accent = Color("accentProgress")
}
