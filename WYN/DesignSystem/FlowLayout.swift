import SwiftUI

/// Layout che dispone i sottoview in righe, andando a capo quando finisce lo spazio.
/// Usato per i tag.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows = layout(subviews: subviews, maxWidth: maxWidth)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        rows.removeAll()
        return CGSize(width: maxWidth == .infinity ? 0 : maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout Void) {
        let rows = layout(subviews: subviews, maxWidth: bounds.width)
        for row in rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private struct RowItem { let index: Int; let x: CGFloat; let size: CGSize }
    private struct Row { var y: CGFloat; var height: CGFloat; var items: [RowItem] }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var items: [RowItem] = []

        for (index, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !items.isEmpty {
                rows.append(Row(y: y, height: rowHeight, items: items))
                y += rowHeight + spacing
                x = 0; rowHeight = 0; items = []
            }
            items.append(RowItem(index: index, x: x, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        if !items.isEmpty { rows.append(Row(y: y, height: rowHeight, items: items)) }
        return rows
    }
}
