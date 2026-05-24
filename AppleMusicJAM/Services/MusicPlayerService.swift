import Combine
import Foundation
import MediaPlayer

// MARK: - NowPlayingState

/// JSON-serializable snapshot of the current playback state.
/// Sent to connected host devices via the `/api/now-playing` endpoint.
struct NowPlayingState: Codable {
    /// The currently playing song, if any.
    var currentSong: Song?
    /// Whether playback is currently active.
    var isPlaying: Bool
    /// The upcoming songs in the queue.
    var queue: [Song]
    /// Elapsed playback time for the current song, in seconds.
    var elapsedTime: Double
    /// Number of host devices currently connected.
    var connectedHosts: Int
}

// MARK: - MusicPlayerService

/// Central music player service that wraps `MPMusicPlayerController.systemMusicPlayer`.
///
/// Provides playback control, queue management, Now Playing info updates,
/// and remote command center integration for system-wide media controls.
@MainActor
final class MusicPlayerService: ObservableObject {

    // MARK: - Singleton

    /// Shared singleton instance.
    static let shared = MusicPlayerService()

    // MARK: - Published Properties

    /// The currently playing song (mapped from local metadata).
    @Published var currentSong: Song?
    /// Whether the player is currently playing.
    @Published var isPlaying: Bool = false
    /// Internal queue of upcoming songs.
    @Published var queue: [Song] = []
    /// Elapsed playback time for the current song, in seconds.
    @Published var elapsedTime: Double = 0

    // MARK: - Private Properties

    /// The system music player instance.
    private let player = MPMusicPlayerController.systemMusicPlayer
    /// Timer that polls playback state every 0.5 seconds.
    private var pollingTimer: Timer?
    /// Set for storing Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupNotifications()
        setupRemoteCommandCenter()
        startPollingTimer()
    }

    deinit {
        pollingTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Authorization

    /// Requests authorization to access the user's Apple Music library.
    func requestAuthorization() {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("[MusicPlayerService] Media library access authorized.")
                case .denied:
                    print("[MusicPlayerService] Media library access denied.")
                case .restricted:
                    print("[MusicPlayerService] Media library access restricted.")
                case .notDetermined:
                    print("[MusicPlayerService] Media library authorization not determined.")
                @unknown default:
                    print("[MusicPlayerService] Unknown authorization status.")
                }
            }
        }
    }

    // MARK: - Playback Control

    /// Plays a specific song immediately, clearing the current queue.
    ///
    /// - Parameter song: The song to play.
    func playSong(_ song: Song) {
        queue.removeAll()
        currentSong = song

        let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [String(song.trackId)])
        player.setQueue(with: descriptor)

        player.prepareToPlay { [weak self] error in
            guard let self else { return }
            if let error {
                print("[MusicPlayerService] Error preparing to play: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.player.play()
                self.isPlaying = true
                self.updateNowPlayingInfo()
            }
        }
    }

    /// Adds a song to the end of the playback queue.
    ///
    /// If nothing is currently playing, the song starts playing immediately.
    /// - Parameter song: The song to enqueue.
    func addToQueue(_ song: Song) {
        queue.append(song)

        if currentSong == nil {
            // Nothing playing — start this song immediately.
            playSong(song)
            if !queue.isEmpty {
                queue.removeFirst()
            }
        } else {
            let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [String(song.trackId)])
            player.append(descriptor)
        }
    }

    /// Inserts a song at the front of the queue so it plays next.
    ///
    /// - Parameter song: The song to insert at the front.
    func playNext(_ song: Song) {
        queue.insert(song, at: 0)

        let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [String(song.trackId)])
        player.prepend(descriptor)
    }

    /// Toggles between play and pause states.
    func togglePlayPause() {
        if player.playbackState == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    /// Skips to the next track.
    func skipNext() {
        if !queue.isEmpty {
            queue.removeFirst()
        }
        player.skipToNextItem()
        isPlaying = true
        updateNowPlayingInfo()
    }

    /// Skips to the previous track.
    func skipPrevious() {
        player.skipToPreviousItem()
        isPlaying = true
        updateNowPlayingInfo()
    }

    // MARK: - Now Playing State

    /// Returns a snapshot of the current playback state for serialization.
    ///
    /// - Parameter connectedHosts: The number of currently connected host devices.
    /// - Returns: A `NowPlayingState` struct.
    func getNowPlayingState(connectedHosts: Int = 0) -> NowPlayingState {
        return NowPlayingState(
            currentSong: currentSong,
            isPlaying: isPlaying,
            queue: queue,
            elapsedTime: elapsedTime,
            connectedHosts: connectedHosts
        )
    }

    // MARK: - Remote Command Center

    /// Configures the system remote command center for media control.
    ///
    /// Handles play, pause, toggle, next track, and previous track commands
    /// from the Lock Screen, Control Center, and connected accessories.
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DispatchQueue.main.async {
                self.player.play()
                self.isPlaying = true
                self.updateNowPlayingInfo()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DispatchQueue.main.async {
                self.player.pause()
                self.isPlaying = false
                self.updateNowPlayingInfo()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DispatchQueue.main.async {
                self.togglePlayPause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DispatchQueue.main.async {
                self.skipNext()
            }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            DispatchQueue.main.async {
                self.skipPrevious()
            }
            return .success
        }
    }

    // MARK: - Now Playing Info

    /// Updates `MPNowPlayingInfoCenter` with the current song's metadata.
    func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = song.trackName
        info[MPMediaItemPropertyArtist] = song.artistName
        info[MPMediaItemPropertyAlbumTitle] = song.collectionName ?? ""
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentPlaybackTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let millis = song.trackTimeMillis {
            info[MPMediaItemPropertyPlaybackDuration] = Double(millis) / 1000.0
        }

        // Attempt to load artwork from URL asynchronously.
        if let urlString = song.artworkUrlLarge, let url = URL(string: urlString) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? info
                        updatedInfo[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                    }
                } catch {
                    print("[MusicPlayerService] Failed to load artwork: \(error.localizedDescription)")
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        
        // Aggiorna anche la Live Activity
        Task {
            await LiveActivityService.shared.updateActivity(
                song: song,
                isPlaying: isPlaying,
                hosts: MQTTService.shared.connectedHosts.count
            )
        }
    }

    // MARK: - Private Methods

    /// Sets up observers for playback state and now-playing-item changes.
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player
        )

        player.beginGeneratingPlaybackNotifications()
    }

    /// Starts the polling timer that updates elapsed time every 0.5 seconds.
    private func startPollingTimer() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.elapsedTime = self.player.currentPlaybackTime
                self.isPlaying = self.player.playbackState == .playing
            }
        }
    }

    /// Called when the now-playing item changes in the system music player.
    @objc private func handleNowPlayingItemChanged() {
        guard let item = player.nowPlayingItem else {
            currentSong = nil
            return
        }

        // Build a Song from the MPMediaItem metadata.
        let song = Song(
            trackId: Int(truncating: item.value(forProperty: MPMediaItemPropertyPersistentID) as? NSNumber ?? 0),
            trackName: item.title ?? "Unknown",
            artistName: item.artist ?? "Unknown",
            collectionName: item.albumTitle,
            artworkUrl100: nil,
            previewUrl: nil,
            trackTimeMillis: Int(item.playbackDuration * 1000)
        )

        currentSong = song
        updateNowPlayingInfo()
    }

    /// Called when the playback state changes.
    @objc private func handlePlaybackStateChanged() {
        isPlaying = player.playbackState == .playing
        updateNowPlayingInfo()
    }
}
