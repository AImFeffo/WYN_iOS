import Foundation
import Supabase

/// Stato di autenticazione dell'app. Osserva la sessione Supabase e la espone
/// alle view. La sessione è persistita da supabase-swift.
@MainActor
@Observable
final class AuthViewModel {
    /// Utente corrente, se loggato.
    var user: User?
    /// True finché non abbiamo determinato lo stato iniziale della sessione.
    var isLoading = true

    private let client = SupabaseManager.client
    private var authTask: Task<Void, Never>?

    var isAuthenticated: Bool { user != nil }

    init() {
        observeAuthState()
    }

    /// Ascolta i cambi di sessione (login, logout, refresh) da supabase-swift.
    private func observeAuthState() {
        authTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    self.user = session?.user
                case .signedOut:
                    self.user = nil
                default:
                    break
                }
                self.isLoading = false
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            throw AuthError.from(error, context: .signIn)
        }
    }

    func signUp(email: String, password: String) async throws {
        do {
            try await client.auth.signUp(email: email, password: password)
        } catch {
            throw AuthError.from(error, context: .signUp)
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        user = nil
    }
}
