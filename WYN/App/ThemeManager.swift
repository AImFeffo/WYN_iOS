import SwiftUI

/// Gestione tema chiaro/scuro. Default: segue il sistema. L'override manuale
/// (dal Profilo) è persistito in UserDefaults.
@MainActor
@Observable
final class ThemeManager {
    enum Mode: String {
        case system, light, dark
    }

    var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    private static let key = "wyn.theme.mode"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? Mode.system.rawValue
        mode = Mode(rawValue: raw) ?? .system
    }

    /// ColorScheme da applicare, o nil per seguire il sistema.
    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Comodo binding on/off per il toggle "Tema scuro".
    var isDark: Bool {
        get { mode == .dark }
        set { mode = newValue ? .dark : .light }
    }
}
