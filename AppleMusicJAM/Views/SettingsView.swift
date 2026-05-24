import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Sessione")) {
                    Toggle("Consenti contenuti espliciti", isOn: .constant(true))
                    Toggle("Richiedi approvazione per host", isOn: .constant(false))
                }
                
                Section(header: Text("Informazioni")) {
                    HStack {
                        Text("Versione")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

#Preview {
    SettingsView()
}
