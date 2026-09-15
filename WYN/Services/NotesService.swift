import Foundation
import Supabase

/// Accesso alla tabella `notes` via supabase-swift. Tutte le operazioni sono
/// protette da RLS (l'utente vede/modifica solo le proprie note).
struct NotesService {
    private var client: SupabaseClient { SupabaseManager.client }

    /// Colonne della nota. `embedding` è esclusa: 512 float per nota inutili al client.
    private static let columns =
        "id,user_id,source_type,url,image_paths,title,summary_points,category,tags,source_name,thumbnail_url,read_time_label,created_at"

    /// Tutte le note dell'utente, ordinate dal più recente.
    func fetchNotes() async throws -> [Note] {
        try await client
            .from("notes")
            .select(Self.columns)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Una singola nota per id (RLS garantisce che sia dell'utente).
    func fetchNote(id: UUID) async throws -> Note {
        try await client
            .from("notes")
            .select(Self.columns)
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    /// Id delle note simili per significato alla query, ordinati per somiglianza.
    /// Chiama la Edge Function `search-notes` (RLS: solo note dell'utente).
    func semanticMatches(query: String) async throws -> [UUID] {
        let response: SemanticSearchResponse = try await client.functions.invoke(
            "search-notes",
            options: FunctionInvokeOptions(body: ["query": query])
        )
        return response.matches.map(\.id)
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

private struct SemanticSearchResponse: Decodable {
    struct Match: Decodable {
        let id: UUID
        let similarity: Double
    }
    let matches: [Match]
}
