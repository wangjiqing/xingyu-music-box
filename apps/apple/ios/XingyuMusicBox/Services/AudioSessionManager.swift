import AVFoundation
import Foundation

enum AudioSessionError: LocalizedError {
    case configureFailed(Error)

    var errorDescription: String? {
        switch self {
        case .configureFailed:
            return "后台播放音频会话配置失败"
        }
    }
}

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configureForPlayback() throws {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
            throw AudioSessionError.configureFailed(error)
        }
    }

    func deactivateIfNeeded() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate AVAudioSession: \(error)")
        }
    }
}
