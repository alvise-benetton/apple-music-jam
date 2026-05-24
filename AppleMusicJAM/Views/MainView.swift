import SwiftUI

/// Primary interface for the Apple Music JAM app.
/// Displays the QR code and connected hosts in a native Apple style layout.
struct MainView: View {
    @ObservedObject private var player = MusicPlayerService.shared
    @ObservedObject private var server = MQTTService.shared

    @State private var showHostsSheet = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    qrCodeCard
                    hostsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Jam")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    serverBadge
                }
            }
            .onAppear(perform: onAppear)
            .sheet(isPresented: $showHostsSheet) {
                ConnectedHostsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Sections

    /// Badge indicating if the local server is running
    private var serverBadge: some View {
        Text(server.isConnected ? "Server is running" : "Server offline")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(server.isConnected ? Color.green : Color.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(server.isConnected ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
            )
    }

    /// Card with QR Code and URL
    private var qrCodeCard: some View {
        VStack(spacing: 16) {
            QRCodeView(url: serverURL, size: 260)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            VStack(spacing: 4) {
                Text("Scan to Join")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(serverURL)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    /// Card showing connected hosts count
    private var hostsCard: some View {
        Button(action: {
            showHostsSheet = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("Connected hosts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(server.connectedHosts.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.purple)
                    .frame(minWidth: 36, minHeight: 36)
                    .padding(.horizontal, 8)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
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
