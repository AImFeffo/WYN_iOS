import Foundation

/// Genera l'export delle note on-device (JSON e Markdown) e restituisce un file
/// temporaneo da condividere con lo share sheet.
enum NoteExporter {
    enum Format { case json, markdown }

    static func makeFile(notes: [Note], format: Format) -> URL? {
        let content: String
        let ext: String
        switch format {
        case .json:
            content = jsonString(notes)
            ext = "json"
        case .markdown:
            content = markdownString(notes)
            ext = "md"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wyn-note.\(ext)")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func jsonString(_ notes: [Note]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(notes),
              let str = String(data: data, encoding: .utf8) else { return "[]" }
        return str
    }

    private static func markdownString(_ notes: [Note]) -> String {
        var lines: [String] = ["# Le mie note WYN", ""]
        for note in notes {
            lines.append("## \(note.title)")
            lines.append("")
            lines.append("_\(note.category)_")
            if let source = note.sourceName { lines.append("Fonte: \(source)") }
            if let url = note.url { lines.append("[\(url)](\(url))") }
            lines.append("")
            for point in note.summaryPoints { lines.append("- \(point)") }
            if !note.tags.isEmpty {
                lines.append("")
                lines.append("Tag: " + note.tags.map { "`\($0)`" }.joined(separator: " "))
            }
            lines.append("")
            lines.append("---")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
