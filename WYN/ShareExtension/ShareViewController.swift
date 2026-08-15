import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Contenuto condiviso ricevuto dall'estensione.
enum SharedContent {
    case link(String)
    case image(UIImage)
}

/// View controller principale della Share Extension. Estrae il contenuto
/// condiviso e mostra una UI SwiftUI per salvarlo in WYN.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        extractSharedContent { [weak self] content in
            guard let self else { return }
            DispatchQueue.main.async {
                self.present(content: content)
            }
        }
    }

    private func present(content: SharedContent?) {
        let root = ShareRootView(
            content: content,
            onClose: { [weak self] in self?.complete() }
        )
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    // MARK: - Estrazione contenuto

    private func extractSharedContent(_ completion: @escaping (SharedContent?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            completion(nil); return
        }

        let urlType = UTType.url.identifier
        let imageType = UTType.image.identifier

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(urlType) {
                provider.loadItem(forTypeIdentifier: urlType, options: nil) { data, _ in
                    if let url = data as? URL, url.scheme?.hasPrefix("http") == true {
                        completion(.link(url.absoluteString))
                    } else {
                        completion(nil)
                    }
                }
                return
            }
        }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(imageType) {
                provider.loadItem(forTypeIdentifier: imageType, options: nil) { data, _ in
                    completion(Self.image(from: data))
                }
                return
            }
        }

        completion(nil)
    }

    private static func image(from data: Any?) -> SharedContent? {
        if let image = data as? UIImage { return .image(image) }
        if let url = data as? URL, let d = try? Data(contentsOf: url),
           let image = UIImage(data: d) { return .image(image) }
        if let d = data as? Data, let image = UIImage(data: d) { return .image(image) }
        return nil
    }
}
