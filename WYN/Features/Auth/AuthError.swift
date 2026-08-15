import Foundation

/// Errore di autenticazione con messaggio in italiano (§4).
struct AuthError: LocalizedError {
    let message: String
    var errorDescription: String? { message }

    enum Context { case signIn, signUp }

    /// Mappa un errore Supabase su un messaggio italiano leggibile.
    static func from(_ error: Error, context: Context) -> AuthError {
        let raw = error.localizedDescription.lowercased()

        if raw.contains("invalid login") || raw.contains("invalid credentials") {
            return AuthError(message: "Email o password non corretti.")
        }
        if raw.contains("already registered") || raw.contains("already been registered")
            || raw.contains("user already") {
            return AuthError(message: "Questa email è già registrata.")
        }
        if raw.contains("password") && raw.contains("6") {
            return AuthError(message: "La password deve avere almeno 6 caratteri.")
        }
        if raw.contains("invalid email") || raw.contains("unable to validate email") {
            return AuthError(message: "Inserisci un indirizzo email valido.")
        }
        if raw.contains("network") || raw.contains("offline")
            || raw.contains("connection") {
            return AuthError(message: "Connessione assente. Riprova.")
        }

        switch context {
        case .signIn:
            return AuthError(message: "Accesso non riuscito. Riprova.")
        case .signUp:
            return AuthError(message: "Registrazione non riuscita. Riprova.")
        }
    }
}
