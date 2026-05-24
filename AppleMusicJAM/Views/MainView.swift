import SwiftUI

struct MainView: View {
    @ObservedObject private var player = MusicPlayerService.shared
    @ObservedObject private var server = MQTTService.shared

    @State private var showHostsSheet = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Jam")
                Spacer()
                Text(server.isConnected ? "Server is running" : "Server offline")
            }
            
            // QR Code Section
            VStack {
                Text("QR Code Placeholder")
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.3))
                Text("Scan to Join")
                Text(serverURL)
            }
            
            // Connected hosts Section
            Button(action: {
                showHostsSheet = true
            }) {
                HStack {
                    Text("Connected hosts")
                    Spacer()
                    Text("\(server.connectedHosts.count)")
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: onAppear)
        .sheet(isPresented: $showHostsSheet) {
            Text("Connected Hosts View Placeholder")
        }
    }

    private var serverURL: String {
        NetworkService.shared.getShareURL(sessionId: server.sessionId)
    }

    private func onAppear() {
        if !server.isConnected {
            server.connect()
        }
    }
}

#Preview {
    MainView()
}
