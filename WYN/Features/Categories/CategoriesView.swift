import SwiftUI

struct CategoriesView: View {
    @Bindable var store: FeedStore
    /// Callback: categoria toccata → il chiamante filtra il feed.
    var onSelect: (Category) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    /// Conteggio note per categoria.
    private var counts: [Category: Int] {
        Dictionary(grouping: store.notes) { Category.from($0.category) }
            .mapValues(\.count)
    }

    /// Solo categorie con almeno una nota, dalla più usata; fallback: tutte.
    private var displayed: [Category] {
        let withNotes = Category.allCases.filter { (counts[$0] ?? 0) > 0 }
        guard !withNotes.isEmpty else { return Category.allCases }
        let order = Dictionary(uniqueKeysWithValues: Category.allCases.enumerated().map { ($1, $0) })
        return withNotes.sorted {
            let (a, b) = (counts[$0] ?? 0, counts[$1] ?? 0)
            return a != b ? a > b : order[$0]! < order[$1]!
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categorie")
                            .font(.heading(28, weight: .semibold))
                            .tracking(-0.6)
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayed) { cat in
                                Button { onSelect(cat) } label: {
                                    CategoryTile(category: cat, count: counts[cat] ?? 0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }
}

struct CategoryTile: View {
    let category: Category
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CategoryBadge(category: category, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(category.displayName)
                    .font(.heading(18, weight: .medium))
                    .foregroundStyle(Color.ink)
                Text(count == 1 ? "1 nota" : "\(count) note")
                    .monoLabel(size: 10)
                    .foregroundStyle(Color.ink3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.hairline, lineWidth: 1))
    }
}
