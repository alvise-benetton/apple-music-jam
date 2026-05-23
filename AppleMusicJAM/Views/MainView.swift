//
//  MainView.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import SwiftUI

/// Primary interface for the Apple Music JAM app.
///
/// Displays the server status, a large QR code for host connections,
/// connected-host count, and a mini Now Playing card at the bottom.
struct MainView: View {

    // MARK: - Observed State

    @ObservedObject private var player = MusicPlayerService.shared
    @ObservedObject private var server = MQTTService.shared

    // MARK: - Local State

    @State private var qrImage: UIImage?
    @State private var isPulsing = false
    @State private var showHostsSheet = false

    // MARK: - Constants

    private let backgroundTop    = Color(hex: "0a0a1a")
    private let backgroundBottom = Color(hex: "1a1033")
    private let accentPurple     = Color(hex: "8b5cf6")
    private let accentPink       = Color(hex: "ec4899")

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [backgroundTop, backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    serverStatusSection
                    qrCodeSection
                    hostsSection
                    if player.currentSong != nil {
                        NowPlayingView()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: player.currentSong?.id)
        .animation(.easeInOut(duration: 0.3), value: server.isConnected)
        .onAppear(perform: onAppear)
        .sheet(isPresented: $showHostsSheet) {
            ConnectedHostsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sections

    /// Animated app title with music note icon.
    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [accentPurple, accentPink], startPoint: .leading, endPoint: .trailing)
                )

            Text("Apple Music JAM")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [accentPurple, accentPink], startPoint: .leading, endPoint: .trailing)
                )
        }
        .padding(.top, 8)
    }

    /// Green/red dot with status label and IP:port information.
    private var serverStatusSection: some View {
        GlassCard {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(server.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: server.isConnected ? .green.opacity(0.6) : .red.opacity(0.6), radius: 6)

                    Text(server.isConnected ? "Server Running" : "Offline")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(server.isConnected ? .green : .red)
                }

                if server.isConnected {
                    Text(serverURL)
                        .font(.caption.monospaced())
                        .foregroundColor(.white.opacity(0.7))
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }

    /// Large QR code with "Scan to Join" label.
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            QRCodeView(url: serverURL, size: 220)

            Text("Scan to Join")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white.opacity(0.85))
                .scaleEffect(isPulsing ? 1.06 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear { isPulsing = true }

            Text(serverURL)
                .font(.caption.monospaced())
                .foregroundColor(.white.opacity(0.5))
        }
    }

    /// Connected hosts count badge, tappable to reveal the hosts sheet.
    private var hostsSection: some View {
        Button {
            showHostsSheet = true
        } label: {
            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(accentPurple)

                    Text("Connected Hosts")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(server.connectedHosts.count)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(
                            LinearGradient(colors: [accentPurple, accentPink], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentPurple.opacity(0.2))
                        )
                }
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// The server URL composed from the public base URL and session ID.
    private var serverURL: String {
        NetworkService.shared.getShareURL(sessionId: server.sessionId)
    }

    /// Called once when the view appears.
    private func onAppear() {
        if !server.isConnected {
            server.connect()
        }
        regenerateQRCode()
    }

    /// Generates (or regenerates) the QR code image for the current server URL.
    private func regenerateQRCode() {
        qrImage = QRCodeService.generateQRCode(from: serverURL, size: 250.0)
    }
}

// MARK: - Glass Card Modifier

/// A reusable glassmorphism container with blur, border, and rounded corners.
struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Hex Color Extension

extension Color {
    /// Creates a `Color` from a 6-character hex string (e.g. `"8b5cf6"`).
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8)  & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .preferredColorScheme(.dark)
}
