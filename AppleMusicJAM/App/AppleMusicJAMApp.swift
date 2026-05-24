//
//  AppleMusicJAMApp.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import SwiftUI
import AVFoundation

/// Main entry point for the Apple Music JAM app.
///
/// Configures the audio session for background playback, requests Apple Music
/// authorization, and sets up the remote command center for lock-screen controls.
@main
struct AppleMusicJAMApp: App {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Initialization

    init() {
        configureAudioSession()
        MusicPlayerService.shared.requestAuthorization()
        MusicPlayerService.shared.setupRemoteCommandCenter()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Private Methods

    /// Configures the shared `AVAudioSession` for `.playback` category so audio
    /// continues when the app is backgrounded or the device is locked.
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("[AppleMusicJAMApp] Failed to configure AVAudioSession: \(error.localizedDescription)")
        }
    }
}
