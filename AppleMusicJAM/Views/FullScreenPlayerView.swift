import SwiftUI

struct FullScreenPlayerView: View {
    @ObservedObject var player = MusicPlayerService.shared
    @Environment(\.dismiss) private var dismiss
    
    // We can use the large artwork for the background blur
    
    var body: some View {
        ZStack {
            // Background Blur based on artwork
            if let song = player.currentSong {
                AsyncImage(url: URL(string: song.artworkUrlLarge ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                            .blur(radius: 60)
                            .overlay(Color.black.opacity(0.3)) // Darken for contrast
                    } else {
                        Color(hex: "1a1033").ignoresSafeArea()
                    }
                }
            } else {
                Color(hex: "1a1033").ignoresSafeArea()
            }
            
            VStack {
                // Drag Handle
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                if let song = player.currentSong {
                    // Copertina Gigante
                    AsyncImage(url: URL(string: song.artworkUrlLarge ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    
                    // Info brano
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.trackName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text(song.artistName)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    
                    // Scrubber (Barra di avanzamento)
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: progressWidth(totalWidth: geometry.size.width, song: song), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        HStack {
                            Text(formatTime(player.elapsedTime))
                            Spacer()
                            Text("-\(formatTime(remainingTime(song: song)))")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    
                    // Controlli principali
                    HStack(spacing: 50) {
                        Button(action: {
                            player.skipPrevious()
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            player.togglePlayPause()
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 46))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            player.skipNext()
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 50)
                    
                    // Barra del volume (estetica/slider di sistema)
                    HStack(spacing: 15) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 12))
                        
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                            .overlay(
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: 150), // Mocked for now, usually MPVolumeView is used
                                alignment: .leading
                            )
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Azioni in basso
                    HStack {
                        Image(systemName: "quote.bubble")
                        Spacer()
                        Image(systemName: "airplayaudio")
                        Spacer()
                        Image(systemName: "list.bullet")
                    }
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                } else {
                    Spacer()
                    Text("Nessun brano in riproduzione")
                        .foregroundColor(.white)
                    Spacer()
                }
            }
        }
    }
    
    private func progressWidth(totalWidth: CGFloat, song: Song) -> CGFloat {
        guard let durationMillis = song.trackTimeMillis, durationMillis > 0 else { return 0 }
        let duration = Double(durationMillis) / 1000.0
        let percentage = player.elapsedTime / duration
        return totalWidth * CGFloat(min(max(percentage, 0), 1))
    }
    
    private func remainingTime(song: Song) -> Double {
        guard let durationMillis = song.trackTimeMillis else { return 0 }
        let duration = Double(durationMillis) / 1000.0
        return max(duration - player.elapsedTime, 0)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    FullScreenPlayerView()
}
