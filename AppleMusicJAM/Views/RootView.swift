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
        ZStack {
            // Contenuto principale
            Group {
                switch selectedTab {
                case .libreria:
                    LibraryView()
                case .jam:
                    MainView()
                case .impostazioni:
                    SettingsView()
                case .cerca:
                    SearchView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Spazio in basso per non coprire il contenuto con la custom tab bar e il mini player
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: player.currentSong != nil ? 150 : 80)
            }
            
            // UI Fluttuante in basso
            VStack(spacing: 8) {
                Spacer()
                
                // Mini Player (Se c'è una canzone)
                if player.currentSong != nil {
                    MiniPlayerView()
                        .onTapGesture {
                            showFullScreenPlayer = true
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Custom Tab Bar
                HStack(spacing: 12) {
                    Spacer(minLength: 0)
                    // Pill principale con i tab primari
                    HStack(spacing: 0) {
                        TabBarButton(title: "Home", icon: "house.fill", tab: .libreria, selectedTab: $selectedTab, namespace: tabAnimationNamespace)
                        TabBarButton(title: "JAM", icon: "music.mic", tab: .jam, selectedTab: $selectedTab, namespace: tabAnimationNamespace)
                        TabBarButton(title: "Opzioni", icon: "gearshape.fill", tab: .impostazioni, selectedTab: $selectedTab, namespace: tabAnimationNamespace)
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
                    
                    // Bottone Circolare Ricerca
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = .cerca
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(selectedTab == .cerca ? .pink : .primary.opacity(0.8))
                            .frame(width: 68, height: 68)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showFullScreenPlayer) {
            FullScreenPlayerView()
        }
        .animation(.spring(), value: player.currentSong != nil)
        .tint(Color.pink)
    }
    
    @Namespace private var tabAnimationNamespace
}

// Bottone singolo della TabBar
struct TabBarButton: View {
    let title: String
    let icon: String
    let tab: AppTab
    @Binding var selectedTab: AppTab
    let namespace: Namespace.ID
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(isSelected ? .pink : .primary.opacity(0.6))
            .frame(width: 72, height: 56)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.pink.opacity(0.15))
                            .matchedGeometryEffect(id: "TAB_BACKGROUND", in: namespace)
                    }
                }
            )
        }
        .buttonStyle(ScaleButtonStyle()) // Using our global ScaleButtonStyle
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.light)
}
