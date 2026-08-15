import Foundation

extension String {
    /// Stringa senza spazi/newline iniziali e finali.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
