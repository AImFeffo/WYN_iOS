import Foundation

/// Configurazione Supabase.
///
/// Contiene SOLO valori pubblici: l'URL del progetto e la chiave `anon`.
/// Queste due sono pensate per stare nel client (protette da RLS).
///
/// ⚠️ NON inserire mai qui la service-role key, la chiave Anthropic o Jina:
/// vivono solo come secret delle Edge Functions.
enum SupabaseConfig {
    static let url = URL(string: "https://odplsmpadzhyhkdoqrne.supabase.co")!

    /// Chiave `anon` (pubblica). Sostituibile senza rischi.
    static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kcGxzbXBhZHpoeWhrZG9xcm5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjQ2MjEsImV4cCI6MjA5MTg0MDYyMX0.siHJxbFrVyThFNy0PS_d38m5s_XB6SoW7J7BEADDCJQ"

    /// App Group condiviso con la Share Extension (Fase 5).
    static let appGroup = "group.com.feffo.wyn"
}
