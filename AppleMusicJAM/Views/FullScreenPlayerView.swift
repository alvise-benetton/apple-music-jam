import SwiftUI

struct FullScreenPlayerView: View {
    @ObservedObject var player = MusicPlayerService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("Chiudi") {
                    dismiss()
                }
            }
            
            if let song = player.currentSong {
                AsyncImage(url: URL(string: song.artworkUrlLarge ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.gray
                    }
                }
                .frame(maxHeight: 300)
                
                VStack {
                    Text(song.trackName)
                    Text(song.artistName)
                }
                
                HStack(spacing: 40) {
                    Button(action: {
                        player.skipPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                    }
                    
                    Button(action: {
                        player.togglePlayPause()
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    }
                    
                    Button(action: {
                        player.skipNext()
                    }) {
                        Image(systemName: "forward.fill")
                    }
                }
                
                Button("Coda") {
                    // TODO: Azione Coda
                }
            } else {
                Text("Nessun brano in riproduzione")
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    FullScreenPlayerView()
}
