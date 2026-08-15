import SwiftUI

extension Color {
    /// Inizializza da un intero esadecimale, es. `Color(hex: 0x2C5266)`.
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

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
}
