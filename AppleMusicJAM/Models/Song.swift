import Foundation

// MARK: - iTunes Search API Response

/// Top-level response from the iTunes Search API.
struct ITunesSearchResponse: Codable {
    /// The number of results returned.
    let resultCount: Int
    /// Array of song results.
    let results: [Song]
}

// MARK: - Song

/// Represents a single song from the iTunes Search API catalog.
/// Maps directly to the JSON fields returned by the `/search` endpoint.
struct Song: Codable, Identifiable, Hashable {

    // MARK: - Properties

    /// Unique track identifier from the iTunes catalog.
    let trackId: Int
    /// Name of the track.
    let trackName: String
    /// Name of the artist.
    let artistName: String
    /// Name of the album/collection (optional — some results omit this field).
    let collectionName: String?
    /// URL string for the 100×100 artwork image (optional).
    let artworkUrl100: String?
    /// URL string for the 30-second audio preview (optional).
    let previewUrl: String?
    /// Duration of the track in milliseconds (optional).
    let trackTimeMillis: Int?

    // MARK: - Identifiable

    /// Conformance to `Identifiable` using the iTunes track ID.
    var id: Int { trackId }

    // MARK: - Computed Properties

    /// Returns a higher-resolution (600×600) artwork URL by scaling up from the 100×100 default.
    var artworkUrlLarge: String? {
        artworkUrl100?.replacingOccurrences(of: "100x100", with: "600x600")
    }

    /// Returns the track duration formatted as `mm:ss`.
    /// Returns `"--:--"` if the duration is unavailable.
    var durationFormatted: String {
        guard let millis = trackTimeMillis else { return "--:--" }
        let totalSeconds = millis / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
