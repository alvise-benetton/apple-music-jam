import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Libreria Personale")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Prossimamente: la tua libreria Apple Music")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Libreria")
        }
    }
}

#Preview {
    LibraryView()
}
