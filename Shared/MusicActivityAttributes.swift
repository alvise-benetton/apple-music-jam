import ActivityKit
import Foundation

/// Attributes for the Apple Music JAM Live Activity.
/// Used to display the currently playing song and session info on the Lock Screen and Dynamic Island.
struct MusicActivityAttributes: ActivityAttributes {
    /// Dynamic state that changes during the Live Activity lifecycle.
    public struct ContentState: Codable, Hashable {
        /// The title of the currently playing song.
        var songTitle: String
        /// The name of the artist performing the song.
        var artistName: String
        /// URL string for the album artwork.
        var albumArtURL: String
        /// Whether music is currently playing.
        var isPlaying: Bool
        /// Number of host devices currently connected to the session.
        var connectedHosts: Int
    }

    /// The display name for this JAM session.
    var sessionName: String
}
