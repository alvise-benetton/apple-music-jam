//
//  NowPlayingView.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import SwiftUI

/// A dark glassmorphism card that shows the currently playing song,
/// playback controls, elapsed time, and a queue count badge.
struct NowPlayingView: View {

    // MARK: - Observed State

    @ObservedObject private var player = MusicPlayerService.shared

    // MARK: - Constants

    private let accentPurple = Color(hex: "8b5cf6")
    private let accentPink   = Color(hex: "ec4899")

    // MARK: - Body

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Top row: artwork + info
                if let song = player.currentSong {
                    songInfoRow(song)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(song.id) // forces re-render on song change
                }

                // Progress
                progressSection

                // Controls
                controlsRow

                // Queue badge
                queueBadge
            }
            .padding(.vertical, 8)
        }
        .animation(.easeInOut(duration: 0.35), value: player.currentSong?.id)
    }

    // MARK: - Sub-views

    /// Album artwork thumbnail, song title, and artist name.
    private func songInfoRow(_ song: Song) -> some View {
        HStack(spacing: 14) {
            artworkImage(for: song)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: accentPurple.opacity(0.4), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.trackName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                if let album = song.collectionName {
                    Text(album)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }

    /// Loads artwork from the song's URL or falls back to a music note icon.
    @ViewBuilder
    private func artworkImage(for song: Song) -> some View {
        AsyncImage(url: URL(string: song.artworkUrlLarge ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                artworkPlaceholder
            case .empty:
                artworkPlaceholder
                    .overlay(ProgressView().tint(.white))
            @unknown default:
                artworkPlaceholder
            }
        }
    }

    /// Placeholder shown when artwork is unavailable.
    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [accentPurple, accentPink], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    /// Elapsed time bar.
    private var progressSection: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(colors: [accentPurple, accentPink], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 4)
                        .animation(.linear(duration: 0.5), value: player.elapsedTime)
                }
            }
            .frame(height: 4)

            HStack {
                Text(formattedTime(player.elapsedTime))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                if let millis = player.currentSong?.trackTimeMillis {
                    Text(formattedTime(Double(millis) / 1000.0))
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    /// Previous / Play-Pause / Next buttons.
    private var controlsRow: some View {
        HStack(spacing: 36) {
            Button { player.skipPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [accentPurple, accentPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: accentPurple.opacity(0.5), radius: 10)
            }

            Button { player.skipNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    /// Shows how many songs remain in the queue.
    private var queueBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet")
                .font(.caption)
                .foregroundColor(accentPurple)

            Text("\(player.queue.count) in queue")
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(accentPurple.opacity(0.15))
        )
    }

    // MARK: - Helpers

    /// Calculates the width of the progress bar based on elapsed vs total time.
    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard let millis = player.currentSong?.trackTimeMillis, millis > 0 else { return 0 }
        let duration = Double(millis) / 1000.0
        let fraction = min(max(player.elapsedTime / duration, 0), 1)
        return totalWidth * fraction
    }

    /// Formats a number of seconds into `m:ss`.
    private func formattedTime(_ seconds: Double) -> String {
        let total = Int(max(seconds, 0))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        NowPlayingView()
            .padding()
    }
    .preferredColorScheme(.dark)
}
