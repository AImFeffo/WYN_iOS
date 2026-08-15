import SwiftUI

struct SearchView: View {
    @Bindable var store: FeedStore

    @State private var query = ""
    @State private var debounced = ""
    @State private var debounceTask: Task<Void, Never>?
    @FocusState private var focused: Bool
    @State private var selectedNote: Note?

    /// Filtro client-side case-insensitive su title, source_name, tags, summary_points.
    private var results: [Note] {
        let q = debounced.trimmed.lowercased()
        guard !q.isEmpty else { return [] }
        return store.notes.filter { note in
            if note.title.lowercased().contains(q) { return true }
            if let s = note.sourceName?.lowercased(), s.contains(q) { return true }
            if note.tags.contains(where: { $0.lowercased().contains(q) }) { return true }
            if note.summaryPoints.contains(where: { $0.lowercased().contains(q) }) { return true }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    searchField
                    resultsContent
                }
                .padding(.top, 12)
            }
            .navigationDestination(item: $selectedNote) { note in
                NoteDetailView(note: note, store: store)
            }
        }
        .onAppear { focused = true }
        .onChange(of: query) { _, newValue in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                debounced = newValue
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.ink3)
            TextField("Cerca per concetto, non per titolo…", text: $query)
                .font(.body(16))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
            if !query.isEmpty {
                Button { query = ""; debounced = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.ink3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var resultsContent: some View {
        if debounced.trimmed.isEmpty {
            emptyPrompt
        } else if results.isEmpty {
            noResults
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text("\(results.count) risultati")
                        .monoLabel(size: 11)
                        .foregroundStyle(Color.ink3)
                        .padding(.horizontal, 20)
                    ForEach(results) { note in
                        Button { selectedNote = note } label: {
                            ResultCard(note: note)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Cerca tra le tue note")
                .font(.heading(19, weight: .medium))
                .foregroundStyle(Color.ink2)
            Spacer()
        }
    }

    private var noResults: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Nessun risultato")
                .font(.heading(19, weight: .medium))
                .foregroundStyle(Color.ink)
            Text("Prova con un altro concetto")
                .font(.body(14))
                .foregroundStyle(Color.ink3)
            Spacer()
        }
    }
}

/// Card compatta per un risultato di ricerca.
struct ResultCard: View {
    let note: Note
    private var category: Category { Category.from(note.category) }

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(category: category, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.heading(16, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(category.displayName)
                    .monoLabel(size: 10)
                    .foregroundStyle(Color.ink3)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.hairline, lineWidth: 1))
    }
}
