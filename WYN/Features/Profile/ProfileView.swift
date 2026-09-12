import SwiftUI

struct ProfileView: View {
    @Bindable var store: FeedStore
    @Environment(AuthViewModel.self) private var auth
    @Environment(ThemeManager.self) private var theme

    @State private var shareURL: URL?
    @State private var showShare = false

    private var email: String { auth.user?.email ?? "" }
    private var displayName: String { String(email.split(separator: "@").first ?? "") }
    private var initial: String { displayName.first.map { String($0).uppercased() } ?? "?" }

    // Statistiche reali.
    private var total: Int { store.notes.count }
    private var articles: Int { store.notes.filter { $0.sourceType == .article }.count }
    private var screenshots: Int { store.notes.filter { $0.sourceType == .screenshot }.count }
    private var topCategory: String {
        let counts = Dictionary(grouping: store.notes) { $0.category }.mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? "—"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        userHeader
                        statsSection
                        settingsSection
                        exportSection
                        infoSection
                        logoutButton
                    }
                    .padding(20)
                }
            }
            .sheet(isPresented: $showShare) {
                if let shareURL { ShareSheet(items: [shareURL]) }
            }
        }
    }

    private var userHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.ink.opacity(0.08))
                Text(initial)
                    .font(.heading(24, weight: .semibold))
                    .foregroundStyle(Color.ink)
            }
            .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName.capitalized)
                    .font(.heading(22, weight: .medium))
                    .foregroundStyle(Color.ink)
                Text(email)
                    .font(.body(14))
                    .foregroundStyle(Color.ink3)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionTitle("Statistiche")
            HStack(spacing: 11) {
                StatTile(value: "\(total)", label: "Note")
                StatTile(value: "\(articles)", label: "Articoli")
                StatTile(value: "\(screenshots)", label: "Screenshot")
            }
            StatTile(value: topCategory, label: "Categoria più usata", wide: true)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionTitle("Impostazioni")
            HStack {
                Text("Tema scuro").font(.body(16)).foregroundStyle(Color.ink)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { theme.isDark },
                    set: { theme.isDark = $0 }
                ))
                .labelsHidden()
                .tint(Color.ink)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1))
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionTitle("Esporta note")
            HStack(spacing: 11) {
                exportButton("JSON") { export(.json) }
                exportButton("Markdown") { export(.markdown) }
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionTitle("Informazioni")
            infoRow("Versione", "1.0.0")
            if let created = auth.user?.createdAt {
                infoRow("Membro da", ItalianDate.memberSince(created))
            }
            Link(destination: URL(string: "mailto:benefede94@gmail.com")!) {
                infoRow("Supporto", "Scrivici", showChevron: true)
            }
        }
    }

    private var logoutButton: some View {
        Button { Task { await auth.signOut() } } label: {
            Text("Logout").monoLabel(size: 13, weight: .semibold)
                .foregroundStyle(Color.danger)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionTitle(_ t: String) -> some View {
        Text(t).monoLabel(size: 11).foregroundStyle(Color.ink3)
    }

    private func exportButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).monoLabel(size: 12, weight: .semibold)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func infoRow(_ label: String, _ value: String, showChevron: Bool = false) -> some View {
        HStack {
            Text(label).font(.body(15)).foregroundStyle(Color.ink)
            Spacer()
            Text(value).font(.body(15)).foregroundStyle(Color.ink3)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkDecor)
            }
        }
        .padding(.vertical, 11)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }

    private func export(_ format: NoteExporter.Format) {
        guard let url = NoteExporter.makeFile(notes: store.notes, format: format) else { return }
        shareURL = url
        showShare = true
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var wide: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.heading(wide ? 22 : 26, weight: .semibold))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .monoLabel(size: 9)
                .foregroundStyle(Color.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.hairline, lineWidth: 1))
    }
}
