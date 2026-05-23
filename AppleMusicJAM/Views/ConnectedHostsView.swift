//
//  ConnectedHostsView.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import SwiftUI

/// Displays the list of host devices currently connected to the JAM server.
///
/// Shows each host's name, relative connection time, and an activity pulse.
/// When no hosts are connected, an empty-state view encourages QR code scanning.
struct ConnectedHostsView: View {

    // MARK: - Observed State

    @ObservedObject private var server = MQTTService.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Constants

    private let accentPurple = Color(hex: "8b5cf6")
    private let accentPink   = Color(hex: "ec4899")

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "0a0a1a"), Color(hex: "1a1033")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if server.connectedHosts.isEmpty {
                    emptyState
                } else {
                    hostsList
                }
            }
            .navigationTitle("Connected Hosts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(accentPurple)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Sub-views

    /// Empty state shown when no hosts are connected.
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [accentPurple, accentPink], startPoint: .top, endPoint: .bottom)
                )

            Text("No Hosts Connected")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("Share the QR code so friends\ncan join and control the music!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Image(systemName: "qrcode.viewfinder")
                .font(.largeTitle)
                .foregroundColor(accentPurple.opacity(0.5))
                .padding(.top, 8)
        }
        .padding()
    }

    /// Scrollable list of currently connected hosts.
    private var hostsList: some View {
        List {
            ForEach(server.connectedHosts) { host in
                hostRow(host)
                    .listRowBackground(Color.white.opacity(0.05))
                    .listRowSeparatorTint(Color.white.opacity(0.08))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.3), value: server.connectedHosts.map(\.id))
    }

    /// A single host row: pulse indicator, name, and relative time.
    private func hostRow(_ host: HostDevice) -> some View {
        HStack(spacing: 14) {
            // Activity pulse
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .shadow(color: .green.opacity(0.6), radius: 4)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        .scaleEffect(1.8)
                        .opacity(0.0)
                        .animation(
                            .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                            value: UUID() // continuous pulse
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(host.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)

                Text(relativeTime(from: host.connectedAt))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.caption)
                .foregroundColor(accentPurple.opacity(0.6))
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    /// Returns a human-readable relative time string (e.g. "2 min ago").
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

// MARK: - Preview

#Preview {
    ConnectedHostsView()
        .preferredColorScheme(.dark)
}
