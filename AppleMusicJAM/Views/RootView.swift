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
                VStack(spacing: 12) {
                    Spacer()
                    
                    // Mini Player (Now Playing Card)
                    if player.currentSong != nil {
                        MiniPlayerView()
                            .onTapGesture {
                                showFullScreenPlayer = true
                            }
                    }
                    
                    // Custom Tab Bar
                    HStack(spacing: 12) {
                        // Pill principale
                        HStack(spacing: 0) {
                            TabBarButton(title: "Library", tab: .libreria, selectedTab: $selectedTab, namespace: tabAnimationNamespace)
                            TabBarButton(title: "Jam", tab: .jam, selectedTab: $selectedTab, namespace: tabAnimationNamespace)
                            TabBarButton(title: "Settings", tab: .impostazioni, selectedTab: $selectedTab, namespace: tabAnimationNamespace)
                        }
                        .padding(6)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                        
                        // Bottone Circolare Ricerca
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = .cerca
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(selectedTab == .cerca ? Color(hex: "a855f7") : .gray)
                                .frame(width: 56, height: 56)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color(hex: "a855f7") : .primary.opacity(0.7))
                .frame(width: 80, height: 44)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(Color(hex: "a855f7").opacity(0.2))
                                .matchedGeometryEffect(id: "TAB_BACKGROUND", in: namespace)
                        }
                    }
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.light)
}
