import Foundation

/// Stato condiviso delle note dell'utente. Caricato una volta e riusato da
/// Feed, Cerca, Categorie e Profilo (come la ricerca client-side della PWA).
@MainActor
@Observable
final class FeedStore {
    var notes: [Note] = []
    var isLoading = false
    var loadError: String?

    /// Card "in elaborazione" mostrate in cima al feed durante il processing.
    var processing: [ProcessingItem] = []
    /// Errori di elaborazione (ErrorCard) da mostrare in cima al feed.
    var processingErrors: [ProcessingError] = []

    private let service = NotesService()

    /// Carica (o ricarica) tutte le note dell'utente.
    func load() async {
        isLoading = true
        loadError = nil
        do {
            notes = try await service.fetchNotes()
        } catch {
            loadError = "Non siamo riusciti a caricare le note."
        }
        isLoading = false
    }

    /// Ricarica silenziosa (dopo un salvataggio), senza spinner a schermo intero.
    func refresh() async {
        do {
            notes = try await service.fetchNotes()
        } catch {
            // In refresh silenzioso non mostriamo errori bloccanti.
        }
    }

    func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
    }

    func updateNoteTags(id: UUID, tags: [String]) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        let n = notes[idx]
        notes[idx] = Note(
            id: n.id, userId: n.userId, sourceType: n.sourceType, url: n.url,
            imagePaths: n.imagePaths, title: n.title, summaryPoints: n.summaryPoints,
            category: n.category, tags: tags, sourceName: n.sourceName,
            thumbnailUrl: n.thumbnailUrl, readTimeLabel: n.readTimeLabel,
            createdAt: n.createdAt
        )
    }
}

/// Un elemento in elaborazione (mostrato con shimmer in cima al feed).
struct ProcessingItem: Identifiable, Equatable {
    let id = UUID()
    let label: String   // es. "lennysnewsletter.com" o "Screenshot"
    let kind: SourceType
}

/// Un errore di elaborazione da mostrare come ErrorCard.
struct ProcessingError: Identifiable, Equatable {
    let id = UUID()
    let message: String
    /// Tipo di contenuto fallito: decide solo l'etichetta della card.
    let kind: SourceType
}
