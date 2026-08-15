import SwiftUI

/// Cornice condivisa delle schermate di autenticazione: sfondo carta,
/// wordmark "WYN" in Newsreader come elemento editoriale, sottotitolo mono.
struct AuthScaffold<Content: View>: View {
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WYN")
                            .font(.heading(56, weight: .semibold))
                            .tracking(-1.5)
                            .foregroundStyle(Color.ink)
                        Text(subtitle)
                            .monoLabel(size: 12, weight: .medium)
                            .foregroundStyle(Color.ink3)
                    }
                    .padding(.top, 48)

                    content
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
