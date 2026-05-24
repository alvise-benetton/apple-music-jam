import Foundation
import AVFoundation

/// Service that plays absolute silence in the background to prevent the 
/// operating system from suspending the application when not in the foreground.
/// This allows the MQTT service to keep receiving commands continuously.
@MainActor
final class SilentAudioService {
    static let shared = SilentAudioService()
    
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    
    private init() {}
    
    func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            // mixWithOthers ensures we don't interrupt the Music app
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            let engine = AVAudioEngine()
            let format = engine.outputNode.inputFormat(forBus: 0)
            
            // Create a node that outputs absolute silence (0s)
            let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in ablPointer {
                    memset(buffer.mData, 0, Int(buffer.mDataByteSize))
                }
                return noErr
            }
            
            engine.attach(srcNode)
            engine.connect(srcNode, to: engine.mainMixerNode, format: format)
            
            try engine.start()
            
            self.audioEngine = engine
            self.sourceNode = srcNode
            print("[SilentAudioService] Started silent AVAudioEngine to keep app alive.")
            
        } catch {
            print("[SilentAudioService] Failed to start silent audio: \(error)")
        }
    }
    
    func stop() {
        audioEngine?.stop()
        audioEngine = nil
        sourceNode = nil
    }
}
