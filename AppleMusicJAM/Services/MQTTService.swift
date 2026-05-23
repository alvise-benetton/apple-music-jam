import Combine
import Foundation
import CocoaMQTT

/// Service that manages the connection to the public MQTT broker.
/// Replaces the old local web server and acts as a serverless relay for Apple Music JAM.
@MainActor
final class MQTTService: ObservableObject {

    // MARK: - Singleton

    static let shared = MQTTService()

    // MARK: - Published Properties

    @Published var isConnected: Bool = false
    @Published var sessionId: String = ""
    @Published var connectedHosts: [HostDevice] = []

    // MARK: - Private Properties

    private var mqttClient: CocoaMQTT?
    private let musicPlayer = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    private var cleanupTimer: Timer?

    private let brokerHost = "broker.hivemq.com"
    private let brokerPort: UInt16 = 1883

    private var stateTopic: String { "apple-music-jam/session/\(sessionId)/state" }
    private var controlTopic: String { "apple-music-jam/session/\(sessionId)/control" }

    // MARK: - JSON Coders

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {
        // Generate a 6-character random alphanumeric session ID
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        sessionId = "JAM-" + String((0..<4).map { _ in characters.randomElement()! })
        
        setupPlayerObservation()
    }

    // MARK: - Connection

    func connect() {
        guard mqttClient == nil else { return }

        let clientID = "JAM-Server-" + UUID().uuidString.prefix(8)
        mqttClient = CocoaMQTT(clientID: clientID, host: brokerHost, port: brokerPort)
        
        mqttClient?.keepAlive = 60
        mqttClient?.autoReconnect = true
        
        // Disable SSL for port 1883. For 8883 you would use enableSSL = true
        mqttClient?.enableSSL = false
        
        mqttClient?.didReceiveMessage = { [weak self] mqtt, message, id in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleMessage(message.string)
            }
        }
        
        mqttClient?.didConnectAck = { [weak self] mqtt, ack in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if ack == .accept {
                    self.isConnected = true
                    print("[MQTTService] Connected to \(self.brokerHost)")
                    mqtt.subscribe(self.controlTopic, qos: .qos1)
                    self.broadcastState()
                } else {
                    print("[MQTTService] Connection failed with ack: \(ack)")
                }
            }
        }
        
        mqttClient?.didDisconnect = { [weak self] mqtt, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isConnected = false
                print("[MQTTService] Disconnected: \(error?.localizedDescription ?? "unknown")")
            }
        }

        let success = mqttClient?.connect()
        print("[MQTTService] Connecting to \(brokerHost)... (\(success == true ? "Success" : "Failed"))")
        
        startCleanupTimer()
    }

    func disconnect() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        mqttClient?.disconnect()
        mqttClient = nil
        isConnected = false
        connectedHosts.removeAll()
    }

    // MARK: - Message Handling

    struct ControlMessage: Codable {
        var action: String
        var song: Song?
        var command: String?
        var clientId: String?
        var name: String?
    }

    private func handleMessage(_ jsonString: String?) {
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8),
              let message = try? decoder.decode(ControlMessage.self, from: data) else {
            return
        }

        switch message.action {
        case "play":
            if let song = message.song {
                musicPlayer.playSong(song)
            }
        case "queue_add":
            if let song = message.song {
                musicPlayer.addToQueue(song)
            }
        case "control":
            if let cmd = message.command {
                switch cmd {
                case "play": musicPlayer.togglePlayPause() // Simplified toggle
                case "pause": musicPlayer.togglePlayPause()
                case "next": musicPlayer.skipNext()
                case "previous": musicPlayer.skipPrevious()
                default: break
                }
            }
        case "heartbeat":
            if let id = message.clientId, let name = message.name {
                registerHeartbeat(id: id, name: name)
            }
        default:
            break
        }
    }

    // MARK: - State Broadcasting

    private func setupPlayerObservation() {
        musicPlayer.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.broadcastState()
            }
            .store(in: &cancellables)
    }

    private func broadcastState() {
        guard isConnected, let mqtt = mqttClient else { return }
        let state = musicPlayer.getNowPlayingState(connectedHosts: connectedHosts.count)
        
        if let data = try? encoder.encode(state),
           let jsonString = String(data: data, encoding: .utf8) {
            mqtt.publish(stateTopic, withString: jsonString, qos: .qos1, retained: true)
        }
    }

    // MARK: - Hosts Management

    private func registerHeartbeat(id: String, name: String) {
        if let index = connectedHosts.firstIndex(where: { $0.id == id }) {
            connectedHosts[index].lastSeenAt = Date()
            connectedHosts[index].name = name
        } else {
            let newHost = HostDevice(id: id, name: name, connectedAt: Date(), lastSeenAt: Date())
            connectedHosts.append(newHost)
            broadcastState() // update count
        }
    }

    private func startCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let cutoff = Date().addingTimeInterval(-30)
                let initialCount = self.connectedHosts.count
                self.connectedHosts.removeAll { $0.lastSeenAt < cutoff }
                if self.connectedHosts.count != initialCount {
                    self.broadcastState() // update count
                }
            }
        }
    }
}
