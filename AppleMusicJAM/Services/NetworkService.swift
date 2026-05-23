import Foundation

/// Service for generating the public URL of the JAM session.
/// The web interface can be hosted on any static hosting (e.g. GitHub Pages).
final class NetworkService {

    // MARK: - Singleton

    static let shared = NetworkService()

    private init() {}

    // MARK: - Configuration

    /// The base URL where the static web application is hosted.
    /// You can change this to your GitHub Pages or Vercel URL.
    private let webAppBaseURL = "https://alvise-benetton.github.io/apple-music-jam"

    // MARK: - Public Methods

    /// Constructs the full shareable URL including the session ID.
    ///
    /// - Parameter sessionId: The unique session ID (e.g. "JAM-X59K").
    /// - Returns: A URL string like "https://alvisebenetton.github.io/apple-music-jam/?session=JAM-X59K"
    func getShareURL(sessionId: String) -> String {
        return "\(webAppBaseURL)/?session=\(sessionId)"
    }
}
