import SwiftUI

/// Filtro attivo del feed: tipo (tutti/articoli/screenshot) + categoria opzionale.
struct FeedFilter: Equatable {
    enum Kind: Equatable { case all, article, screenshot }
    var kind: Kind = .all
    var category: Category? = nil

    func matches(_ note: Note) -> Bool {
        let kindOK: Bool
        switch kind {
        case .all:        kindOK = true
        case .article:    kindOK = note.sourceType == .article
        case .screenshot: kindOK = note.sourceType == .screenshot
        }
        let catOK = category == nil || Category.from(note.category) == category
        return kindOK && catOK
    }
}

/// Riga orizzontale di chip filtro. Tipo e categoria sono combinabili.
struct FilterChips: View {
    @Binding var filter: FeedFilter
    /// Categorie presenti tra le note (per mostrare solo chip utili).
    let availableCategories: [Category]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Tutti", active: filter.kind == .all && filter.category == nil) {
                    filter.kind = .all; filter.category = nil
                }
                chip("Articoli", active: filter.kind == .article) {
                    filter.kind = filter.kind == .article ? .all : .article
                }
                chip("Screenshot", active: filter.kind == .screenshot) {
                    filter.kind = filter.kind == .screenshot ? .all : .screenshot
                }

                ForEach(availableCategories) { cat in
                    chip(cat.displayName, active: filter.category == cat, tint: cat.color) {
                        filter.category = filter.category == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func chip(_ label: String, active: Bool, tint: Color? = nil,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.mono(11, weight: .medium))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(active ? Color.surface : Color.ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? (tint ?? Color.ink) : Color.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.hairline, lineWidth: active ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
