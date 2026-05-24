import SwiftUI

/// Primary interface for the Apple Music JAM app.
/// Displays the QR code and connected hosts in a native Apple style layout.
struct MainView: View {
    @ObservedObject private var player = MusicPlayerService.shared
    @ObservedObject private var server = MQTTService.shared

    @State private var showHostsSheet = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header custom come nello screenshot
                HStack {
                    Text("Jam")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(server.isConnected ? "Server is running" : "Server offline")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(server.isConnected ? Color(hex: "65a30d") : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(server.isConnected ? Color(hex: "ecfccb") : Color.red.opacity(0.15))
                        )
                }
                .padding(.horizontal, 4)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        qrCodeCard
                        hostsCard
                    }
                    .padding(.bottom, 150) // Spazio per il tab bar e now playing
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .onAppear(perform: onAppear)
        .sheet(isPresented: $showHostsSheet) {
            ConnectedHostsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Card with QR Code and URL
    private var qrCodeCard: some View {
        VStack(spacing: 16) {
            QRCodeView(url: serverURL, size: 280)
                .padding(.top, 24)

            VStack(spacing: 4) {
                Text("Scan to Join")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(serverURL)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }

    /// Card showing connected hosts count
    private var hostsCard: some View {
        Button(action: {
            showHostsSheet = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "a855f7"))

                Text("Connected hosts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(server.connectedHosts.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "9333ea"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "e9d5ff"))
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(24)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Helpers

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

// MARK: - Hex Color Extension

extension Color {
    /// Creates a `Color` from a 6-character hex string (e.g. `"8b5cf6"`).
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8)  & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Glass Card Modifier

/// A reusable glassmorphism container with blur, border, and rounded corners.
struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}
