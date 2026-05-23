//
//  CarPlaySceneDelegate.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import UIKit
import CarPlay
import Combine

/// Manages the CarPlay interface, presenting a Now Playing template with a
/// QR-code button that reveals the server URL so passengers can connect.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    // MARK: - Properties

    /// Reference to the CarPlay interface controller provided by the system.
    private var interfaceController: CPInterfaceController?

    /// Combine subscriptions for observing player state changes.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        configureNowPlayingTemplate(nowPlayingTemplate)

        interfaceController.setRootTemplate(nowPlayingTemplate, animated: true) { success, error in
            if let error = error {
                print("[CarPlaySceneDelegate] Failed to set root template: \(error.localizedDescription)")
            }
        }

        observePlayerChanges()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        cancellables.removeAll()
        self.interfaceController = nil
    }

    // MARK: - Template Configuration

    /// Adds a QR-code button to the Now Playing template so the user can
    /// retrieve the server URL on the CarPlay display.
    private func configureNowPlayingTemplate(_ template: CPNowPlayingTemplate) {
        let qrButton = CPNowPlayingImageButton(image: UIImage(systemName: "qrcode")!) { [weak self] _ in
            self?.showServerURLAlert()
        }
        template.updateNowPlayingButtons([qrButton])
    }

    /// Presents an alert on the CarPlay display showing the current server URL.
    private func showServerURLAlert() {
        let serverURL = NetworkService.shared.getShareURL(sessionId: MQTTService.shared.sessionId)
        let hostsCount = MQTTService.shared.connectedHosts.count

        let alert = CPAlertTemplate(
            titleVariants: ["Apple Music JAM"],
            actions: [
                CPAlertAction(title: "Session: \(MQTTService.shared.sessionId)", style: .default) { [weak self] _ in
                    self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                },
                CPAlertAction(title: "\(hostsCount) host(s) connected", style: .cancel) { [weak self] _ in
                    self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                }
            ]
        )

        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }

    // MARK: - Observation

    /// Observes `MusicPlayerService` for song / playback state changes and
    /// updates the CarPlay Now Playing template accordingly.
    private func observePlayerChanges() {
        let player = MusicPlayerService.shared

        player.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)
    }

    /// Refreshes the Now Playing information displayed on CarPlay whenever the
    /// underlying player state changes.
    private func updateNowPlayingInfo() {
        // The system reads from MPNowPlayingInfoCenter automatically, so we
        // only need to ensure the buttons stay current.
        let template = CPNowPlayingTemplate.shared
        configureNowPlayingTemplate(template)
    }
}
