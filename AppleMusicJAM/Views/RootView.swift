import SwiftUI

enum AppTab {
    case libreria
    case jam
    case impostazioni
    case cerca
}

struct RootView: View {
    @State private var selectedTab: AppTab = .jam
    @State private var showFullScreenPlayer = false
    @ObservedObject var player = MusicPlayerService.shared

    var body: some View {
        VStack {
            // Contenuto principale
            Group {
                switch selectedTab {
                case .libreria:
                    Text("Library")
                case .jam:
                    MainView()
                case .impostazioni:
                    Text("Settings")
                case .cerca:
                    Text("Search")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Mini Player Skeleton
            if player.currentSong != nil {
                MiniPlayerView()
                    .onTapGesture {
                        showFullScreenPlayer = true
                    }
            }
            
            // Tab Bar Skeleton
            HStack(spacing: 20) {
                Button("Library") { selectedTab = .libreria }
                Button("Jam") { selectedTab = .jam }
                Button("Settings") { selectedTab = .impostazioni }
                Button("Search") { selectedTab = .cerca }
            }
            .padding()
        }
        .sheet(isPresented: $showFullScreenPlayer) {
            FullScreenPlayerView()
        }
    }
}

#Preview {
    RootView()
}
