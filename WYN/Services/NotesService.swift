import Foundation
import Supabase

/// Accesso alla tabella `notes` via supabase-swift. Tutte le operazioni sono
/// protette da RLS (l'utente vede/modifica solo le proprie note).
struct NotesService {
    private var client: SupabaseClient { SupabaseManager.client }

    /// Tutte le note dell'utente, ordinate dal più recente.
    func fetchNotes() async throws -> [Note] {
        try await client
            .from("notes")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Una singola nota per id (RLS garantisce che sia dell'utente).
    func fetchNote(id: UUID) async throws -> Note {
        try await client
            .from("notes")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    /// Aggiorna i tag di una nota (normalizzati). Rispetta RLS (client utente).
    func updateTags(noteId: UUID, tags: [String]) async throws {
        try await client
            .from("notes")
            .update(["tags": tags])
            .eq("id", value: noteId)
            .execute()
    }

    /// Elimina una nota (solo se dell'utente).
    func deleteNote(id: UUID) async throws {
        try await client
            .from("notes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// URL firmato per uno screenshot nel bucket privato (validità 1 ora).
    func signedImageURL(path: String) async throws -> URL {
        try await client.storage
            .from("screenshots")
            .createSignedURL(path: path, expiresIn: 3600)
    }
}
