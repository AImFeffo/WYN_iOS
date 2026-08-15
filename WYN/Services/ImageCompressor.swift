import UIKit

/// Compressione immagini on-device prima dell'invio (§4.2):
/// lato massimo 1568 px (fit inside, mai ingrandire), JPEG qualità 0,85.
enum ImageCompressor {
    private static let maxSide: CGFloat = 1568
    private static let quality: CGFloat = 0.85

    static func compressedJPEG(_ image: UIImage) -> Data? {
        let resized = resize(image)
        return resized.jpegData(compressionQuality: quality)
    }

    private static func resize(_ image: UIImage) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        // Mai ingrandire.
        guard longest > maxSide else { return image }

        let scale = maxSide / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1  // pixel effettivi, non punti retina
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
