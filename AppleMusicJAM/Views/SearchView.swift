import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Nessuna ricerca recente")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Le ricerche recenti verranno\nvisualizzate qui")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if isSearching {
                    ProgressView("Ricerca in corso...")
                } else {
                    List(searchResults) { song in
                        HStack {
                            AsyncImage(url: URL(string: song.artworkUrl100 ?? "")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(6)
                                } else {
                                    Color.gray.opacity(0.3)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(6)
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text(song.trackName)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(song.artistName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Aggiungi in coda
                                MusicPlayerService.shared.addToQueue(song)
                                // Invia notifica o feedback
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Cerca")
            .searchable(text: $searchText, prompt: "Artisti, brani, testi e molto altro")
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    searchResults = []
                } else {
                    performSearch(query: newValue)
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        isSearching = true
        Task {
            do {
                let results = try await ITunesSearchService.shared.search(term: query)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                print("Errore durante la ricerca: \(error)")
                await MainActor.run {
                    self.isSearching = false
                }
            }
        }
    }
}

#Preview {
    SearchView()
}
