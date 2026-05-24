//
//  AppDelegate.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import UIKit
import AVFoundation
import CarPlay

/// Application delegate responsible for scene configuration, audio session
/// setup, and starting the MQTT service on launch.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        LocationService.shared.startTracking()
        startMQTTService()
        return true
    }

    /// Returns the appropriate scene configuration depending on whether the
    /// connecting session is a CarPlay session or a regular window session.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {

        // CarPlay template application scene
        if connectingSceneSession.role == UISceneSession.Role.carTemplateApplication {
            let configuration = UISceneConfiguration(
                name: "CarPlay Configuration",
                sessionRole: connectingSceneSession.role
            )
            configuration.delegateClass = CarPlaySceneDelegate.self
            return configuration
        }

        // Default window scene
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        return configuration
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // No-op – reserved for future cleanup.
    }

    // MARK: - Private Methods



    /// Starts the MQTT service so that host devices can connect.
    private func startMQTTService() {
        let service = MQTTService.shared
        if !service.isConnected {
            service.connect()
        }
    }
}
