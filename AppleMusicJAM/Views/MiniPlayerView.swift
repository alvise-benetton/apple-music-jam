import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var player = MusicPlayerService.shared
    
    // GeometryReader size from parent
    var height: CGFloat = 64
    
    var body: some View {
        if let song = player.currentSong {
            VStack(spacing: 0) {
                // Sottile linea di progress
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                        
                        Rectangle()
                            .fill(Color.primary)
                            .frame(width: progressWidth(totalWidth: geometry.size.width, song: song))
                    }
                }
                .frame(height: 2)
                
                HStack(spacing: 12) {
                    // Artwork
                    AsyncImage(url: URL(string: song.artworkUrl100 ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .cornerRadius(6)
                                .shadow(radius: 4)
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(width: 44, height: 44)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.leading, 12)
                    
                    // Titolo e Artista
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.trackName)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        Text(song.artistName)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Controlli
                    Button(action: {
                        player.togglePlayPause()
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }
                    
                    Button(action: {
                        player.skipNext()
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 8)
                }
                .frame(height: height - 2) // Minus the progress bar height
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 8)
        }
    }
    
    private func progressWidth(totalWidth: CGFloat, song: Song) -> CGFloat {
        guard let durationMillis = song.trackTimeMillis, durationMillis > 0 else { return 0 }
        let duration = Double(durationMillis) / 1000.0
        let percentage = player.elapsedTime / duration
        return totalWidth * CGFloat(min(max(percentage, 0), 1))
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.black
        MiniPlayerView()
            .padding(.bottom, 20)
    }
    .preferredColorScheme(.dark)
}
