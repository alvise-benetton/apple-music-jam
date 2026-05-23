//
//  MusicLiveActivity.swift
//  AppleMusicJAMWidget
//
//  Created by Apple Music JAM.
//

import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity that shows the currently playing song and connected host
/// count on the Lock Screen and Dynamic Island.
struct MusicLiveActivity: Widget {

    // MARK: - Constants

    private static let accentPurple = Color(red: 0x8B / 255, green: 0x5C / 255, blue: 0xF6 / 255)
    private static let accentPink   = Color(red: 0xEC / 255, green: 0x48 / 255, blue: 0x99 / 255)

    // MARK: - Body

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MusicActivityAttributes.self) { context in
            // ── Lock Screen / Banner presentation ──
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded regions ──
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.songTitle)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "music.note")
                            .foregroundStyle(Self.accentPurple)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(Self.accentPink)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Label("\(context.state.connectedHosts)", systemImage: "person.2.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Self.accentPurple)
                    }
                    .padding(.horizontal, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                // ── Compact leading ──
                Image(systemName: "music.quarternote.3")
                    .foregroundStyle(Self.accentPurple)
            } compactTrailing: {
                // ── Compact trailing ──
                Text(context.state.songTitle)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            } minimal: {
                // ── Minimal ──
                Image(systemName: "music.note")
                    .foregroundStyle(Self.accentPurple)
            }
        }
    }

    // MARK: - Lock Screen View

    /// Full-width Lock Screen / banner Live Activity presentation.
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<MusicActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            // Album art placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Self.accentPurple, Self.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                let urlString = context.state.albumArtURL
                if !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Song info
            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.songTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(context.state.artistName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Play/pause icon
            Image(systemName: context.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Self.accentPurple, Self.accentPink],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Hosts badge
            if context.state.connectedHosts > 0 {
                Label("\(context.state.connectedHosts)", systemImage: "person.2.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Self.accentPurple.opacity(0.6))
                    )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x1A / 255),
                    Color(red: 0x1A / 255, green: 0x10 / 255, blue: 0x33 / 255)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Preview

// Removed preview to fix compiler error
