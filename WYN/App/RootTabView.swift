import SwiftUI

/// TabView principale a 4 tab (Feed, Cerca, Categorie, Profilo).
/// Il `FeedStore` è condiviso tra le tab (le note si caricano una volta sola).
struct RootTabView: View {
    @State private var store = FeedStore()
    @State private var selection: Tab = .feed
    /// Categoria selezionata da "Categorie" per filtrare il feed.
    @State private var feedCategory: Category?

    enum Tab { case feed, search, categories, profile }

    var body: some View {
        TabView(selection: $selection) {
            FeedView(store: store, forcedCategory: $feedCategory)
                .tabItem { Label("Feed", systemImage: "square.stack") }
                .tag(Tab.feed)

            SearchView(store: store)
                .tabItem { Label("Cerca", systemImage: "magnifyingglass") }
                .tag(Tab.search)

            CategoriesView(store: store) { category in
                feedCategory = category
                selection = .feed
            }
            .tabItem { Label("Categorie", systemImage: "circle.grid.2x2") }
            .tag(Tab.categories)

            ProfileView(store: store)
                .tabItem { Label("Profilo", systemImage: "person") }
                .tag(Tab.profile)
        }
        .tint(Color.ink)
        .task {
            if store.notes.isEmpty { await store.load() }
        }
    }
}
