import Foundation

/// Represents a remote host device connected to the JAM session.
/// Each host connects via the web interface served by the local server
/// and is tracked for heartbeat/presence detection.
struct HostDevice: Identifiable, Codable {
    /// Unique identifier for this host (UUID string).
    let id: String
    /// Display name for this host (derived from User-Agent or a custom name).
    var name: String
    /// Timestamp when the host first connected.
    let connectedAt: Date
    /// Timestamp of the host's most recent heartbeat.
    var lastSeenAt: Date

    /// Creates a new HostDevice with a generated UUID and the current timestamp.
    /// - Parameter name: Display name for the host.
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.connectedAt = Date()
        self.lastSeenAt = Date()
    }

    /// Memberwise initializer for decoding or manual construction.
    init(id: String, name: String, connectedAt: Date, lastSeenAt: Date) {
        self.id = id
        self.name = name
        self.connectedAt = connectedAt
        self.lastSeenAt = lastSeenAt
    }
}
