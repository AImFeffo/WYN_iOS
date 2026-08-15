import Foundation

/// Origine del contenuto di una nota.
enum SourceType: String, Codable, Sendable {
    case article
    case screenshot
}

/// Nota strutturata generata dall'AI. Speculare alla tabella `notes` (§3).
struct Note: Codable, Identifiable, Sendable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    let sourceType: SourceType
    let url: String?
    let imagePaths: [String]?
    let title: String
    let summaryPoints: [String]
    let category: String
    let tags: [String]
    let sourceName: String?
    let thumbnailUrl: String?
    let readTimeLabel: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sourceType = "source_type"
        case url
        case imagePaths = "image_paths"
        case title
        case summaryPoints = "summary_points"
        case category
        case tags
        case sourceName = "source_name"
        case thumbnailUrl = "thumbnail_url"
        case readTimeLabel = "read_time_label"
        case createdAt = "created_at"
    }
}
