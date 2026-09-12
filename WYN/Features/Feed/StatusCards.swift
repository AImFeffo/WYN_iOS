import SwiftUI

/// Card "in arrivo" mostrata in cima al feed durante l'elaborazione: tre passi
/// e uno scheletro della nota che si sta componendo.
///
/// L'avanzamento dei passi è puramente decorativo (timer): la Edge Function è
/// una singola chiamata e non espone lo stato intermedio.
struct ProcessingCard: View {
    let item: ProcessingItem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var shimmer = false

    private var steps: [String] {
        [item.kind == .article ? "Pagina letta" : "Testo letto", "Sintesi", "Categoria"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.accent)
                Text("\(item.label) · in arrivo")
                    .monoLabel(size: 9.5)
                    .foregroundStyle(Color.ink3)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.accent : Color.hairline)
                        .frame(height: 3)
                }
            }

            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, label in
                    if i > 0 { Spacer() }
                    Text(label)
                        .monoLabel(size: 9)
                        .foregroundStyle(i <= step ? Color.accent : Color.ink3)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                skeletonLine(height: 15, fraction: 0.88)
                skeletonLine(height: 15, fraction: 0.54)
                skeletonLine(height: 9, fraction: 0.76)
            }
            .padding(.top, 4)
            .opacity(shimmer ? 0.55 : 1)
        }
        .padding(EdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18))
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            advance(to: 1)
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            advance(to: 2)
        }
    }

    private func advance(to value: Int) {
        if reduceMotion {
            step = value
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { step = value }
        }
    }

    private func skeletonLine(height: CGFloat, fraction: CGFloat) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.ink.opacity(0.09), Color.ink.opacity(0.04)],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: geo.size.width * fraction)
        }
        .frame(height: height)
    }
}

/// ErrorCard mostrata quando l'elaborazione fallisce: causa (etichetta per tipo),
/// messaggio del server, azione "Scarta".
struct ErrorCard: View {
    let message: String
    let kind: SourceType
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Text("!")
                    .font(.mono(10, weight: .semibold))
                    .foregroundStyle(Color.surface)
                    .frame(width: 15, height: 15)
                    .background(Color.danger)
                    .clipShape(Circle())
                Text(kind == .article ? "Link non elaborato" : "Screenshot non elaborato")
                    .monoLabel(size: 10, weight: .semibold)
                    .foregroundStyle(Color.danger)
            }
            Text(message)
                .font(.body(13.5))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onClose) {
                Text("Scarta")
                    .monoLabel(size: 10.5, weight: .semibold)
                    .foregroundStyle(Color.ink2)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(EdgeInsets(top: 15, leading: 16, bottom: 15, trailing: 16))
        .background(Color.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.danger.opacity(0.25), lineWidth: 1)
        )
    }
}
