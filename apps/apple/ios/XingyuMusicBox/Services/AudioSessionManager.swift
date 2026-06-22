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

    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: ((_ shouldResume: Bool) -> Void)?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

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

    @objc private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            onInterruptionBegan?()
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            onInterruptionEnded?(options.contains(.shouldResume))
        @unknown default:
            break
        }
    }
}
