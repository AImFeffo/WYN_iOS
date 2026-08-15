import SwiftUI

/// Card "in elaborazione" con shimmer, mostrata in cima al feed durante il processing.
struct ProcessingCard: View {
    let item: ProcessingItem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer = false

    var body: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(Color.ink2)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.kind == .article ? "Elaborazione link…" : "Elaborazione screenshot…")
                    .monoLabel(size: 10)
                    .foregroundStyle(Color.ink3)
                Text(item.label)
                    .font(.body(15))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
        .opacity(shimmer ? 0.6 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

/// ErrorCard mostrata quando l'elaborazione fallisce.
struct ErrorCard: View {
    let message: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.danger)
            Text(message)
                .font(.body(14))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: onClose) {
                Text("Chiudi").monoLabel(size: 10, weight: .semibold)
                    .foregroundStyle(Color.ink2)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.danger.opacity(0.25), lineWidth: 1)
        )
    }
}
