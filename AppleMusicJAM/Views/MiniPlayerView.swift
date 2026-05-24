import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var player = MusicPlayerService.shared
    
    var body: some View {
        if let song = player.currentSong {
            HStack {
                AsyncImage(url: URL(string: song.artworkUrl100 ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().frame(width: 50, height: 50)
                    } else {
                        Color.gray.frame(width: 50, height: 50)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(song.trackName)
                    Text(song.artistName)
                }
                
                Spacer()
                
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
            .padding()
        }
    }
}

#Preview {
    MiniPlayerView()
}
