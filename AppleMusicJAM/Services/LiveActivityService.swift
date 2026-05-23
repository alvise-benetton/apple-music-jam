import ActivityKit
import Foundation

/// Service for managing the Apple Music JAM Live Activity.
///
/// Displays the currently playing song, playback state, and connected host count
/// on the Lock Screen and Dynamic Island using ActivityKit.
final class LiveActivityService {

    // MARK: - Singleton

    /// Shared singleton instance.
    static let shared = LiveActivityService()

    // MARK: - Private Properties

    /// The currently active Live Activity, if any.
    private var currentActivity: Activity<MusicActivityAttributes>?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Starts a new Live Activity displaying the given song and host count.
    ///
    /// If a Live Activity is already running, it will be ended before starting a new one.
    /// Does nothing if Live Activities are not enabled on this device.
    ///
    /// - Parameters:
    ///   - song: The song to display.
    ///   - hosts: The number of connected host devices.
    func startActivity(song: Song, hosts: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivityService] Live Activities are not enabled.")
            return
        }

        // End any existing activity before starting a new one.
        if currentActivity != nil {
            endActivity()
        }

        let attributes = MusicActivityAttributes(sessionName: "Apple Music JAM")

        let contentState = MusicActivityAttributes.ContentState(
            songTitle: song.trackName,
            artistName: song.artistName,
            albumArtURL: song.artworkUrlLarge ?? song.artworkUrl100 ?? "",
            isPlaying: true,
            connectedHosts: hosts
        )

        let content = ActivityContent(state: contentState, staleDate: nil)

        do {
            currentActivity = try Activity<MusicActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("[LiveActivityService] Live Activity started.")
        } catch {
            print("[LiveActivityService] Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// Updates the current Live Activity with new playback state.
    ///
    /// - Parameters:
    ///   - song: The currently playing song, or `nil` if nothing is playing.
    ///   - isPlaying: Whether playback is currently active.
    ///   - hosts: The number of connected host devices.
    func updateActivity(song: Song?, isPlaying: Bool, hosts: Int) async {
        guard let activity = currentActivity else {
            print("[LiveActivityService] No active Live Activity to update.")
            return
        }

        let contentState = MusicActivityAttributes.ContentState(
            songTitle: song?.trackName ?? "No Song",
            artistName: song?.artistName ?? "",
            albumArtURL: song?.artworkUrlLarge ?? song?.artworkUrl100 ?? "",
            isPlaying: isPlaying,
            connectedHosts: hosts
        )

        let content = ActivityContent(state: contentState, staleDate: nil)

        await activity.update(content)
        print("[LiveActivityService] Live Activity updated.")
    }

    /// Ends the current Live Activity.
    ///
    /// Displays a final state with "Session Ended" before dismissing.
    func endActivity() {
        guard let activity = currentActivity else {
            print("[LiveActivityService] No active Live Activity to end.")
            return
        }

        let finalState = MusicActivityAttributes.ContentState(
            songTitle: "Session Ended",
            artistName: "",
            albumArtURL: "",
            isPlaying: false,
            connectedHosts: 0
        )

        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .default)
            print("[LiveActivityService] Live Activity ended.")
        }

        currentActivity = nil
    }
}
