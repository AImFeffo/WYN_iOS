import Foundation

/// Formattazioni date in italiano usate in tutta l'app.
enum ItalianDate {
    private static let locale = Locale(identifier: "it_IT")

    /// Data del masthead, es. "Martedì 8 Luglio" (giorno settimana + giorno + mese, capitalizzati).
    static func masthead(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: date).capitalizedFirstOfEachWord
    }

    /// Tempo relativo in italiano, es. "2 ore fa", "adesso".
    static func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = locale
        f.unitsStyle = .full
        let interval = date.timeIntervalSinceNow
        if abs(interval) < 60 { return "adesso" }
        return f.localizedString(for: date, relativeTo: Date())
    }

    /// Data "Membro da", es. "Aprile 2026".
    static func memberSince(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date).capitalizedFirstOfEachWord
    }
}

private extension String {
    /// Capitalizza la prima lettera di ogni parola (per nomi di giorni/mesi italiani).
    var capitalizedFirstOfEachWord: String {
        split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
