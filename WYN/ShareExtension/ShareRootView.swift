import SwiftUI
import UserNotifications

/// UI della Share Extension: anteprima del contenuto, hint opzionale,
/// bottone "Salva in WYN" → Edge Function → conferma e chiusura.
struct ShareRootView: View {
    let content: SharedContent?
    let onClose: () -> Void

    @State private var hint = ""
    @State private var state: ShareState = .idle

    private let processing = ProcessingService()

    enum ShareState: Equatable {
        case idle, saving, done, error(String)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
                .onTapGesture { if state != .saving { onClose() } }
            card
                .padding(.horizontal, 20)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Salva in WYN")
                    .font(.custom("Newsreader", size: 22).weight(.medium))
                    .foregroundStyle(Color.ink)
                Spacer()
                Button { onClose() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink3)
                }
                .disabled(state == .saving)
            }

            preview
            hintField
            actionArea
        }
        .padding(22)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var preview: some View {
        switch content {
        case .link(let url):
            Label(url, systemImage: "link")
                .font(.custom("Geist", size: 14))
                .foregroundStyle(Color.ink2)
                .lineLimit(2)
        case .image(let image):
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        case .none:
            Text("Contenuto non supportato.")
                .font(.custom("Geist", size: 14))
                .foregroundStyle(Color.danger)
        }
    }

    private var hintField: some View {
        TextField("Cosa vuoi evidenziare? (facoltativo)", text: $hint, axis: .vertical)
            .font(.custom("Geist", size: 15))
            .foregroundStyle(Color.ink)
            .lineLimit(1...2)
            .onChange(of: hint) { _, v in
                if v.count > 150 { hint = String(v.prefix(150)) }
            }
            .padding(12)
            .background(Color.bg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1))
            .disabled(content == nil)
    }

    @ViewBuilder
    private var actionArea: some View {
        switch state {
        case .done:
            Label("Nota salvata", systemImage: "checkmark.circle.fill")
                .font(.custom("Geist Mono", size: 12).weight(.semibold))
                .foregroundStyle(Category.salute.color)
                .frame(maxWidth: .infinity, minHeight: 52)
        case .error(let message):
            VStack(spacing: 8) {
                Text(message)
                    .font(.custom("Geist", size: 13))
                    .foregroundStyle(Color.danger)
                saveButton(title: "Riprova")
            }
        default:
            saveButton(title: "Salva in WYN")
        }
    }

    private func saveButton(title: String) -> some View {
        Button(action: save) {
            if state == .saving {
                ProgressView().tint(Color.surface)
            } else {
                Text(title)
                    .font(.custom("Geist Mono", size: 13).weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color.ink.opacity(content == nil ? 0.35 : 1))
        .foregroundStyle(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .disabled(content == nil || state == .saving)
    }

    private func save() {
        guard let content else { return }
        state = .saving
        let hintValue = hint.trimmed.isEmpty ? nil : hint.trimmed

        Task {
            do {
                switch content {
                case .link(let url):
                    try await processing.processLink(url: url, hint: hintValue)
                case .image(let image):
                    try await processing.processScreenshot(image: image, hint: hintValue)
                }
                await notifySaved()
                state = .done
                try? await Task.sleep(for: .seconds(1))
                onClose()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    /// Notifica locale al completamento (chiede il permesso al primo uso).
    private func notifySaved() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        let content = UNMutableNotificationContent()
        content.title = "Nota salvata"
        content.body = "Il contenuto è stato aggiunto a WYN."
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil
        )
        try? await center.add(request)
    }
}
