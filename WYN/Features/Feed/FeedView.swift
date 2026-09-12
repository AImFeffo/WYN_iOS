import SwiftUI

struct FeedView: View {
    @Bindable var store: FeedStore
    /// Categoria imposta da "Categorie" (mostra il banner "← Tutte le note").
    @Binding var forcedCategory: Category?

    @State private var filter = FeedFilter()
    @State private var linkText = ""
    @State private var linkHint = ""
    @State private var isSavingLink = false
    @State private var selectedNote: Note?
    @State private var showScreenshotSheet = false

    private let processing = ProcessingService()

    /// Categorie presenti tra le note, per le chip.
    private var availableCategories: [Category] {
        let present = Set(store.notes.map { Category.from($0.category) })
        return Category.allCases.filter { present.contains($0) }
    }

    private var visibleNotes: [Note] {
        store.notes.filter { note in
            if let forced = forcedCategory {
                return Category.from(note.category) == forced
            }
            return filter.matches(note)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                content
            }
            .navigationDestination(item: $selectedNote) { note in
                NoteDetailView(note: note, store: store)
            }
            .sheet(isPresented: $showScreenshotSheet) {
                ScreenshotSheet { image, hint in
                    saveScreenshot(image: image, hint: hint)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                masthead
                    .padding(.horizontal, 20)

                AddBar(
                    linkText: $linkText,
                    hint: $linkHint,
                    isBusy: isSavingLink,
                    onSave: saveLink,
                    onCamera: { showScreenshotSheet = true }
                )
                .padding(.horizontal, 20)

                if forcedCategory != nil {
                    categoryBanner.padding(.horizontal, 20)
                } else {
                    FilterChips(filter: $filter, availableCategories: availableCategories)
                }

                // Card di elaborazione ed errori in cima.
                ForEach(store.processing) { item in
                    ProcessingCard(item: item).padding(.horizontal, 20)
                }
                ForEach(store.processingErrors) { err in
                    ErrorCard(message: err.message, kind: err.kind) {
                        store.processingErrors.removeAll { $0.id == err.id }
                    }
                    .padding(.horizontal, 20)
                }

                if store.isLoading && store.notes.isEmpty {
                    loadingState
                } else if visibleNotes.isEmpty && store.processing.isEmpty {
                    emptyState
                } else {
                    ForEach(visibleNotes) { note in
                        Button { selectedNote = note } label: {
                            NoteCard(note: note)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .refreshable { await store.load() }
        .scrollDismissesKeyboard(.immediately)
    }

    private var masthead: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("WYN")
                .font(.heading(30, weight: .semibold))
                .tracking(-1)
                .foregroundStyle(Color.ink)
            Spacer()
            Text(ItalianDate.masthead())
                .monoLabel(size: 11)
                .foregroundStyle(Color.ink3)
        }
    }

    private var categoryBanner: some View {
        Button {
            forcedCategory = nil
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Tutte le note").monoLabel(size: 11, weight: .semibold)
            }
            .foregroundStyle(Color.ink2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Nessuna nota ancora")
                .font(.heading(20, weight: .medium))
                .foregroundStyle(Color.ink)
            Text("Incolla un link o carica uno screenshot qui sopra")
                .font(.body(14))
                .foregroundStyle(Color.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 40)
    }

    private var loadingState: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
    }

    // MARK: - Azioni

    private func saveLink() {
        let url = linkText.trimmed
        guard !url.isEmpty, !isSavingLink else { return }
        let hint = linkHint.trimmed
        let item = ProcessingItem(label: displayLabel(for: url), kind: .article)

        linkText = ""
        linkHint = ""
        isSavingLink = true
        store.processing.append(item)

        Task {
            defer { isSavingLink = false }
            do {
                try await processing.processLink(url: url, hint: hint.isEmpty ? nil : hint)
                await store.refresh()
                Haptics.success()
            } catch {
                store.processingErrors.append(ProcessingError(message: error.localizedDescription, kind: .article))
            }
            store.processing.removeAll { $0.id == item.id }
        }
    }

    private func saveScreenshot(image: UIImage, hint: String?) {
        let item = ProcessingItem(label: "Screenshot", kind: .screenshot)
        store.processing.append(item)
        Task {
            do {
                try await processing.processScreenshot(image: image, hint: hint)
                await store.refresh()
                Haptics.success()
            } catch {
                store.processingErrors.append(ProcessingError(message: error.localizedDescription, kind: .screenshot))
            }
            store.processing.removeAll { $0.id == item.id }
        }
    }

    /// Etichetta leggibile per la card di elaborazione (hostname senza www).
    private func displayLabel(for url: String) -> String {
        if let host = URL(string: url)?.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return url
    }
}
