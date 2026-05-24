import SwiftUI

struct RootView: View {
    @State private var selectedTab = 1
    @State private var showFullScreenPlayer = false
    @ObservedObject var player = MusicPlayerService.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                LibraryView()
                    .tabItem {
                        Label("Libreria", systemImage: "music.note.house.fill")
                    }
                    .tag(0)
                
                MainView() // La nostra ex-MainView, che ora funge da tab "JAM"
                    .tabItem {
                        Label("JAM", systemImage: "music.mic")
                    }
                    .tag(1)
                
                SearchView()
                    .tabItem {
                        Label("Cerca", systemImage: "magnifyingglass")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Impostazioni", systemImage: "gear")
                    }
                    .tag(3)
            }
            // Aggiungiamo un safe area inset se c'è una canzone, per non far
            // coprire gli elementi dal mini-player
            .safeAreaInset(edge: .bottom) {
                if player.currentSong != nil {
                    Color.clear.frame(height: 72)
                }
            }
            
            // Il Mini Player fluttuante
            if player.currentSong != nil {
                MiniPlayerView()
                    .padding(.bottom, 49) // Altezza standard della tab bar
                    .onTapGesture {
                        showFullScreenPlayer = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2) // Assicurati che sia sopra la tab bar
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPlayer) {
            FullScreenPlayerView()
        }
        .animation(.spring(), value: player.currentSong != nil)
        // Tint color in stile Apple Music
        .tint(Color(hex: "ec4899"))
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
