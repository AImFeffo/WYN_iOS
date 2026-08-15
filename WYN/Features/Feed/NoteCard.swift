import SwiftUI

/// Card di una nota nel feed. Estetica editoriale: badge categoria, titolo serif,
/// riga meta monospace, tag.
struct NoteCard: View {
    let note: Note

    private var category: Category { Category.from(note.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                CategoryBadge(category: category, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.displayName)
                        .monoLabel(size: 10)
                        .foregroundStyle(category.color)
                    Text(metaLine)
                        .monoLabel(size: 10)
                        .foregroundStyle(Color.ink3)
                }
                Spacer()
                Image(systemName: note.sourceType == .article ? "link" : "photo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ink3)
            }

            Text(note.title)
                .font(.heading(21, weight: .medium))
                .tracking(-0.4)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            if let first = note.summaryPoints.first {
                Text(first)
                    .font(.body(14))
                    .foregroundStyle(Color.ink2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !note.tags.isEmpty {
                TagRow(tags: Array(note.tags.prefix(4)))
            }
        }
        .padding(18)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
    }

    private var metaLine: String {
        var parts: [String] = []
        if let source = note.sourceName, !source.isEmpty { parts.append(source) }
        if let read = note.readTimeLabel, !read.isEmpty { parts.append(read) }
        parts.append(ItalianDate.relative(note.createdAt))
        return parts.joined(separator: " · ")
    }
}

/// Riga di tag minuscoli in stile "pillola" tenue.
struct TagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.mono(10, weight: .medium))
                    .foregroundStyle(Color.ink2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ink.opacity(0.05))
                    .clipShape(Capsule())
            }
        }
    }
}
