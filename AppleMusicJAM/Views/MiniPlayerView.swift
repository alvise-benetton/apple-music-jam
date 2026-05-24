import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var player = MusicPlayerService.shared
    
    // GeometryReader size from parent
    var height: CGFloat = 68
    
    var body: some View {
        if let song = player.currentSong {
            VStack(spacing: 0) {
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
                    .buttonStyle(ScaleButtonStyle())
                    
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
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.trailing, 8)
                }
                .frame(height: height)
            }
            .background(
                ZStack(alignment: .bottom) {
                    // Sfondo sfocato della copertina
                    AsyncImage(url: URL(string: song.artworkUrl100 ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 30)
                                .opacity(0.7)
                        } else {
                            Color.clear
                        }
                    }
                    
                    // Materiale translucido principale
                    Rectangle()
                        .fill(.regularMaterial)
                    
                    // Sottile linea di progress in basso, sovrapposta
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.clear) // Invisibile base
                            
                            Rectangle()
                                .fill(Color.primary.opacity(0.8))
                                .frame(width: progressWidth(totalWidth: geometry.size.width, song: song))
                        }
                    }
                    .frame(height: 2)
                }
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 16)
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
