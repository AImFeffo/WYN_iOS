import SwiftUI

struct SearchView: View {
    @Bindable var store: FeedStore

    @State private var query = ""
    @State private var debounced = ""
    @State private var debounceTask: Task<Void, Never>?
    @FocusState private var focused: Bool
    @State private var selectedNote: Note?

    /// Termine normalizzato usato sia dal filtro sia dall'evidenziazione.
    private var term: String { debounced.trimmed.lowercased() }

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
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ink2)
            TextField("Cerca una parola nelle note…", text: $query)
                .font(.body(16))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
            if !query.isEmpty {
                Button { query = ""; debounced = "" } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 22, height: 22)
                        .background(Color.ink.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(focused ? Color.ink : Color.hairline, lineWidth: focused ? 1.5 : 1))
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
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(results.count) risultati")
                            .monoLabel(size: 11)
                            .foregroundStyle(Color.ink3)
                        Spacer()
                        Text("Corrispondenza testuale")
                            .monoLabel(size: 9)
                            .foregroundStyle(Color.ink3)
                    }
                    .padding(.horizontal, 20)
                    ForEach(results) { note in
                        Button { selectedNote = note } label: {
                            ResultCard(note: note, term: term)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("La ricerca confronta il testo, non il significato")
                    .font(.heading(22, weight: .medium))
                    .tracking(-0.4)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Scrivi una parola che compare nella nota. Cercare «come risparmiare» non trova una nota che parla di «TER» e «commissioni».")
                    .font(.body(14.5))
                    .foregroundStyle(Color.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Campi confrontati")
                        .monoLabel(size: 9)
                        .foregroundStyle(Color.ink3)
                        .padding(.bottom, 8)
                    comparedField("Titolo")
                    comparedField("Punti chiave")
                    comparedField("Tag")
                    comparedField("Nome della fonte")
                    Rectangle().fill(Color.hairline).frame(height: 1)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func comparedField(_ name: String) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.hairline).frame(height: 1)
            HStack {
                Text(name).font(.body(14)).foregroundStyle(Color.ink)
                Spacer()
                Text("testo esatto").font(.mono(11)).foregroundStyle(Color.ink3)
            }
            .padding(.vertical, 10)
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

/// Dove il termine ha fatto match. Stessa precedenza del filtro `results`.
enum SearchMatch {
    case title, source, tag(String), keyPoint(String)

    static func find(in note: Note, term q: String) -> SearchMatch {
        if note.title.lowercased().contains(q) { return .title }
        if let s = note.sourceName?.lowercased(), s.contains(q) { return .source }
        if let t = note.tags.first(where: { $0.lowercased().contains(q) }) { return .tag(t) }
        if let p = note.summaryPoints.first(where: { $0.lowercased().contains(q) }) { return .keyPoint(p) }
        return .title
    }

    var label: String {
        switch self {
        case .title:    return "Trovato nel titolo"
        case .source:   return "Trovato nella fonte"
        case .tag:      return "Trovato nei tag"
        case .keyPoint: return "Trovato nei punti chiave"
        }
    }
}

/// Evidenzia tutte le occorrenze (case-insensitive) di `term` con lo sfondo `match`.
func highlighted(_ text: String, term: String) -> AttributedString {
    var result = AttributedString(text)
    guard !term.isEmpty else { return result }
    var searchRange = text.startIndex..<text.endIndex
    while let found = text.range(of: term, options: .caseInsensitive, range: searchRange) {
        if let range = Range(found, in: result) {
            result[range].backgroundColor = Color.match
        }
        searchRange = found.upperBound..<text.endIndex
    }
    return result
}

/// Card di un risultato: titolo, dove ha fatto match, termine evidenziato nel contesto.
struct ResultCard: View {
    let note: Note
    let term: String

    private var category: Category { Category.from(note.category) }
    private var match: SearchMatch { SearchMatch.find(in: note, term: term) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                CategoryBadge(category: category, size: 32)
                Text(highlighted(note.title, term: term))
                    .font(.heading(17, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Category.business.color)
                    .frame(width: 3, height: 10)
                Text(match.label)
                    .monoLabel(size: 9, weight: .semibold)
                    .foregroundStyle(Color.ink2)
            }

            switch match {
            case .keyPoint(let point):
                Text(highlighted("«\(point)»", term: term))
                    .font(.body(13.5))
                    .foregroundStyle(Color.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            case .tag(let hit):
                HStack(spacing: 6) {
                    ForEach(Array(note.tags.prefix(4)), id: \.self) { tag in
                        Text(tag)
                            .font(.mono(10.5, weight: tag == hit ? .semibold : .medium))
                            .foregroundStyle(tag == hit ? Color.ink : Color.ink2)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(tag == hit ? Color.match : Color.fill)
                            .clipShape(Capsule())
                    }
                }
            case .source:
                if let source = note.sourceName {
                    Text(highlighted(source, term: term))
                        .font(.body(13.5))
                        .foregroundStyle(Color.ink)
                }
            case .title:
                EmptyView()
            }
        }
        .padding(EdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.hairline, lineWidth: 1))
    }
}
