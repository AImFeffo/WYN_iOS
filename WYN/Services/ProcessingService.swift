import Foundation
import UIKit
import Supabase

/// Invoca le Edge Functions di elaborazione (process-link, process-screenshot)
/// con la sessione utente. Le chiavi segrete restano lato server.
struct ProcessingService {
    private var client: SupabaseClient { SupabaseManager.client }

    /// Errore con messaggio in italiano (riusa i messaggi del server quando presenti).
    struct ProcessingFailure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private static let genericError = "Non siamo riusciti a elaborare questo contenuto"

    /// Elabora un link. Ritorna l'id della nota creata.
    @discardableResult
    func processLink(url: String, hint: String?) async throws -> String {
        var body: [String: String] = ["url": url]
        if let hint, !hint.isEmpty { body["hint"] = hint }
        return try await invoke("process-link", body: body)
    }

    /// Comprime ed elabora uno screenshot. Ritorna l'id della nota creata.
    @discardableResult
    func processScreenshot(image: UIImage, hint: String?) async throws -> String {
        guard let jpeg = ImageCompressor.compressedJPEG(image) else {
            throw ProcessingFailure(message: Self.genericError)
        }
        var body: [String: String] = ["image": jpeg.base64EncodedString()]
        if let hint, !hint.isEmpty { body["hint"] = hint }
        return try await invoke("process-screenshot", body: body)
    }

    // MARK: - Private

    private func invoke(_ name: String, body: [String: String]) async throws -> String {
        do {
            let response: NoteIdResponse = try await client.functions.invoke(
                name,
                options: FunctionInvokeOptions(body: body)
            )
            return response.id
        } catch let FunctionsError.httpError(_, data) {
            // Il server ritorna { "error": "messaggio in italiano" }.
            throw ProcessingFailure(message: Self.serverMessage(from: data))
        } catch let failure as ProcessingFailure {
            throw failure
        } catch {
            throw ProcessingFailure(message: Self.genericError)
        }
    }

    private static func serverMessage(from data: Data) -> String {
        if let obj = try? JSONDecoder().decode([String: String].self, from: data),
           let msg = obj["error"], !msg.isEmpty {
            return msg
        }
        return genericError
    }
}

private struct NoteIdResponse: Decodable {
    let id: String
}
