import SwiftUI

struct NoteDetailView: View {
    let note: Note
    @Bindable var store: FeedStore
    @Environment(\.dismiss) private var dismiss

    @State private var tags: [String]
    @State private var imageURL: URL?
    @State private var showTagEditor = false
    @State private var showDeleteConfirm = false
    @State private var showShare = false
    @State private var showSafari = false
    @State private var shareItems: [Any] = []

    private let service = NotesService()

    init(note: Note, store: FeedStore) {
        self.note = note
        self.store = store
        _tags = State(initialValue: note.tags)
    }

    private var category: Category { Category.from(note.category) }
    private var articleURL: URL? { note.url.flatMap(URL.init(string:)) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if note.sourceType == .screenshot { screenshotImage }
                    keyPoints
                    if !tags.isEmpty { tagsSection }
                    Spacer(minLength: note.sourceType == .article ? 80 : 20)
                }
                .padding(20)
            }

            if note.sourceType == .article, articleURL != nil {
                openOriginalButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { share() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Condividi").monoLabel(size: 10.5, weight: .semibold)
                    }
                    .foregroundStyle(Color.ink)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showTagEditor = true } label: {
                        Label("Modifica tag", systemImage: "tag")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.ink)
                }
            }
        }
        .sheet(isPresented: $showTagEditor) {
            TagEditorSheet(tags: tags) { newTags in
                Task { await saveTags(newTags) }
            }
        }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showSafari) {
            if let url = articleURL { SafariView(url: url).ignoresSafeArea() }
        }
        .confirmationDialog("Eliminare questa nota?", isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Elimina", role: .destructive) { Task { await delete() } }
            Button("Annulla", role: .cancel) {}
        }
        .task { await loadImageIfNeeded() }
    }

    // MARK: - Sezioni

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            CategoryBadge(category: category, size: 48)
            Text(note.title)
                .font(.heading(30, weight: .medium))
                .tracking(-0.6)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text(category.displayName)
                    .monoLabel(size: 11)
                    .foregroundStyle(category.color)
                Text("·").foregroundStyle(Color.ink3)
                Text(ItalianDate.relative(note.createdAt))
                    .monoLabel(size: 11)
                    .foregroundStyle(Color.ink3)
                if let source = note.sourceName, !source.isEmpty {
                    Text("·").foregroundStyle(Color.ink3)
                    Text(source).monoLabel(size: 11).foregroundStyle(Color.ink3)
                }
                if let read = note.readTimeLabel {
                    Text("·").foregroundStyle(Color.ink3)
                    Text(read).monoLabel(size: 11).foregroundStyle(Color.ink3)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }

    @ViewBuilder
    private var screenshotImage: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                case .failure:
                    placeholderImage
                default:
                    placeholderImage.overlay(ProgressView())
                }
            }
        } else {
            placeholderImage.overlay(ProgressView())
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.ink.opacity(0.05))
            .frame(height: 200)
    }

    private var keyPoints: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Punti chiave").monoLabel(size: 11).foregroundStyle(Color.ink3)
            ForEach(Array(note.summaryPoints.enumerated()), id: \.offset) { _, point in
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(category.color).frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(point)
                        .font(.body(16))
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tag").monoLabel(size: 11).foregroundStyle(Color.ink3)
            FlowTags(tags: tags)
        }
    }

    private var openOriginalButton: some View {
        Button { showSafari = true } label: {
            Text("Apri articolo originale").monoLabel(size: 13, weight: .semibold)
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(
            LinearGradient(colors: [Color.bg.opacity(0), Color.bg],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 100).allowsHitTesting(false),
            alignment: .bottom
        )
    }

    // MARK: - Azioni

    private func loadImageIfNeeded() async {
        guard note.sourceType == .screenshot,
              let path = note.imagePaths?.first, imageURL == nil else { return }
        imageURL = try? await service.signedImageURL(path: path)
    }

    private func saveTags(_ newTags: [String]) async {
        let normalized = TagNormalizer.normalize(newTags)
        do {
            try await service.updateTags(noteId: note.id, tags: normalized)
            tags = normalized
            store.updateNoteTags(id: note.id, tags: normalized)
        } catch {
            // In caso di errore lasciamo i tag invariati.
        }
    }

    private func delete() async {
        do {
            try await service.deleteNote(id: note.id)
            store.removeNote(id: note.id)
            dismiss()
        } catch {}
    }

    private func share() {
        if let url = articleURL {
            shareItems = [url]
        } else {
            shareItems = [note.title]
        }
        showShare = true
    }
}
