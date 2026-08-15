import Foundation
import Supabase

/// Storage della sessione supabase-swift in un file dentro il container dell'App Group,
/// così app ed estensione condividono la stessa sessione utente.
///
/// (Scelta rispetto al Keychain access group per funzionare sul simulatore senza Team ID.)
struct AppGroupStorage: AuthLocalStorage {
    private let containerURL: URL

    init(appGroup: String) {
        self.containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
    }

    private func fileURL(for key: String) -> URL {
        // I nomi delle chiavi possono contenere caratteri non validi per un path.
        let safe = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return containerURL.appendingPathComponent("sb-\(safe).json")
    }

    func store(key: String, value: Data) throws {
        try value.write(to: fileURL(for: key), options: .atomic)
    }

    func retrieve(key: String) throws -> Data? {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    func remove(key: String) throws {
        let url = fileURL(for: key)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
