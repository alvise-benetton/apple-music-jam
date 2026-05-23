import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Service for generating QR codes to share the JAM session URL with host devices.
final class QRCodeService {

    // MARK: - Private

    /// Shared Core Image context for rendering CIImages to CGImages.
    private static let context = CIContext()

    // MARK: - Public Methods

    /// Generates a QR code image from the given string.
    ///
    /// Uses `CIFilter.qrCodeGenerator()` with error correction level "H" (high)
    /// for maximum readability even if partially obscured.
    ///
    /// - Parameters:
    ///   - string: The data to encode in the QR code (typically a URL).
    ///   - size: The desired output size in points. Defaults to 512.
    /// - Returns: A `UIImage` containing the QR code, or `nil` if generation fails.
    static func generateQRCode(from string: String, size: CGFloat = 512) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"

        guard let ciImage = filter.outputImage else {
            return nil
        }

        // Calculate the scale factor to reach the desired output size.
        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Render to a CGImage for crisp, non-interpolated output.
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
